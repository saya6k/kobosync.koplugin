-- Menu that lays its page out as a grid of covers.
--
-- KOReader's Menu hardcodes MenuItem when it builds a row (the MenuItem:new
-- call inside Menu:updateItems) and MenuItem composes text widgets only, so
-- there is no hook for an image, let alone a multi-column page. The bundled
-- CoverBrowser plugin works around this by replacing FileChooser.updateItems
-- wholesale; the same is done here, except scoped to this subclass so nothing
-- global is patched.
--
-- The consequence is that this file mirrors the shape of Menu:updateItems as of
-- KOReader v2026.03 and will drift if that method's contract changes. The grid
-- is therefore opt-in, and any error while building it falls back to the stock
-- rendering for the rest of the session.

local CenterContainer = require("ui/widget/container/centercontainer")
local Font = require("ui/font")
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local ImageWidget = require("ui/widget/imagewidget")
local InputContainer = require("ui/widget/container/inputcontainer")
local Menu = require("ui/widget/menu")
local Size = require("ui/size")
local TextWidget = require("ui/widget/textwidget")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local UIManager = require("ui/uimanager")
local logger = require("logger")

-- The cover box is reserved whether or not the image has been fetched, so
-- cells do not jump around as covers arrive.
local GRID_CAPTION_FONT_SIZE = 14

-- Measured rather than derived: a Font face carries no height accessor, and
-- KOReader scales font sizes per device, so the only reliable number comes from
-- laying a string out. The fallback is a rough guess for the case where the
-- probe itself fails, so a grid still renders.
local function caption_height(font_size)
    local ok, height = pcall(function()
        local probe = TextWidget:new{
            text = "Ag",
            face = Font:getFace("cfont", font_size),
        }
        local h = probe:getSize().h
        probe:free()
        return h
    end)
    if ok and height then
        return height
    end
    return math.floor(font_size * 1.6)
end

-- One cell of the grid: a large cover with the title underneath.
local CoverGridItem = InputContainer:extend{
    entry = nil,
    cover_file = nil,
    menu = nil,
    font_size = GRID_CAPTION_FONT_SIZE,
}

function CoverGridItem:init()
    self.ges_events = {
        TapSelect = {
            GestureRange:new{ ges = "tap", range = self.dimen },
        },
        HoldSelect = {
            GestureRange:new{ ges = "hold", range = self.dimen },
        },
    }

    local padding = Size.padding.small
    local caption_face = Font:getFace("cfont", self.font_size)
    local caption = TextWidget:new{
        text = self.text or "",
        face = caption_face,
        max_width = self.dimen.w - 2 * padding,
    }
    local cover_h = self.dimen.h - caption:getSize().h - 3 * padding
    local cover_w = self.dimen.w - 2 * padding

    local cover
    if self.cover_file then
        cover = ImageWidget:new{
            file = self.cover_file,
            width = cover_w,
            height = cover_h,
            scale_factor = 0,
        }
    else
        cover = VerticalSpan:new{ width = cover_h }
    end

    self[1] = CenterContainer:new{
        dimen = self.dimen:copy(),
        VerticalGroup:new{
            align = "center",
            CenterContainer:new{
                dimen = Geom:new{ w = cover_w, h = cover_h },
                cover,
            },
            VerticalSpan:new{ width = padding },
            caption,
        },
    }
end

function CoverGridItem:onTapSelect()
    if self.entry and self.entry.callback then
        self.entry.callback()
    end
    return true
end

function CoverGridItem:onHoldSelect()
    if self.menu and self.menu.onMenuHold then
        self.menu:onMenuHold(self.entry)
    end
    return true
end

local CoverMenu = Menu:extend{
    -- Injected by the caller: entry -> cached cover path or nil, and
    -- entry -> true once a cover has been fetched (or has failed).
    cover_file_func = nil,
    fetch_cover_func = nil,
    -- Cells per row. Three fills a portrait e-ink screen without shrinking a
    -- 2:3 cover below what the list mode already gave.
    kobosync_grid_cols = 3,
}

-- The page holds cols x rows cells rather than `items_per_page` rows, so the
-- geometry Menu computed has to be replaced. Everything paging depends on
-- (perpage, item_dimen, page_num, page) is recomputed here, which keeps Menu's
-- own paging arithmetic correct.
function CoverMenu:_recalculateDimen(no_recalculate_dimen)
    -- Menu derives a page count from its own perpage and clamps self.page to
    -- it. A grid fits fewer items per page, so that count is too small and the
    -- clamp strands paging partway through the list -- asking for page 3 of a
    -- 4-page grid left it on page 2 forever. Remember what was asked for and
    -- re-clamp against the grid's own count below.
    local requested_page = self.page
    Menu._recalculateDimen(self, no_recalculate_dimen)
    -- Once the grid has failed, this has to become a plain pass-through:
    -- leaving grid geometry (perpage, item_dimen) behind for the stock builder
    -- to work with is how a fallback turns into a second, worse crash.
    if self.kobosync_covers_broken or not self.available_height then
        return
    end
    local cols = self.kobosync_grid_cols
    local cell_w = math.floor(self.inner_dimen.w / cols)
    -- A 2:3 cover plus a caption line; the cell is as tall as that needs.
    local caption_h = caption_height(GRID_CAPTION_FONT_SIZE) + 2 * Size.padding.small
    local cell_h = math.floor(cell_w * 3 / 2) + caption_h
    local rows = math.max(1, math.floor(self.available_height / cell_h))
    -- Spread any leftover height over the rows rather than leaving a gap.
    cell_h = math.floor(self.available_height / rows)

    self.kobosync_grid_rows = rows
    self.perpage = cols * rows
    self.item_dimen = Geom:new{ x = 0, y = 0, w = cell_w, h = cell_h }
    self.page_num = self:getPageNumber(#self.item_table)
    self.page = math.max(1, math.min(requested_page or 1, self.page_num))
end

-- Mirrors Menu:updateItems, laying cells out in rows instead of building one
-- MenuItem per line. Shortcuts and the items_max_lines layout are not
-- reproduced: this menu uses neither.
function CoverMenu:_buildCoverItems(select_number, no_recalculate_dimen)
    local old_dimen = self.dimen and self.dimen:copy()
    self.layout = {}
    self.item_group:clear()
    self.page_info:resetLayout()
    self.return_button:resetLayout()
    self.content_group:resetLayout()
    self:_recalculateDimen(no_recalculate_dimen)

    local items_nb = self.perpage
    local idx_offset = (self.page - 1) * items_nb
    local missing = {}
    local cols = self.kobosync_grid_cols
    local row_group, row_layout

    for idx = 1, items_nb do
        local index = idx_offset + idx
        local item = self.item_table[index]
        if item == nil then break end
        item.idx = index
        if index == self.itemnumber then
            select_number = idx
        end
        local cover_file = self.cover_file_func and self.cover_file_func(item) or nil
        if not cover_file and self.fetch_cover_func then
            table.insert(missing, item)
        end
        local text = self.getMenuText and self.getMenuText(item) or item.text
        local widget = CoverGridItem:new{
            text = text,
            entry = item,
            cover_file = cover_file,
            menu = self,
            dimen = self.item_dimen:copy(),
            show_parent = self.show_parent,
        }
        if (idx - 1) % cols == 0 then
            row_group = HorizontalGroup:new{}
            row_layout = {}
            table.insert(self.item_group, row_group)
            table.insert(self.layout, row_layout)
        end
        table.insert(row_group, widget)
        table.insert(row_layout, widget)
    end

    self:updatePageInfo(select_number)
    self:mergeTitleBarIntoLayout()

    UIManager:setDirty(self.show_parent, function()
        local refresh_dimen = old_dimen and old_dimen:combine(self.dimen) or self.dimen
        return "ui", refresh_dimen
    end)

    -- Covers the page is missing are fetched after it has been drawn, never
    -- before: fetching inline would hold up every page turn by as long as the
    -- downloads take. Each one is attempted once per session, so a book whose
    -- cover cannot be fetched does not retry on every repaint.
    if #missing > 0 then
        UIManager:nextTick(function()
            local fetched = false
            for _, item in ipairs(missing) do
                if self.fetch_cover_func(item) then
                    fetched = true
                end
            end
            if fetched then
                self:updateItems(nil, true)
            end
        end)
    end
end

function CoverMenu:updateItems(select_number, no_recalculate_dimen)
    if self.kobosync_covers_broken then
        return Menu.updateItems(self, select_number, no_recalculate_dimen)
    end
    -- xpcall with a traceback, not pcall: the message alone ("attempt to call a
    -- nil value") says nothing about which line, which is exactly what is
    -- needed when this only fails on someone else's device.
    local ok, err = xpcall(function()
        return self:_buildCoverItems(select_number, no_recalculate_dimen)
    end, debug.traceback)
    if not ok then
        logger.warn("KoboSync: cover rows failed, falling back to the plain list:", err)
        self.kobosync_covers_broken = true
        return Menu.updateItems(self, select_number, no_recalculate_dimen)
    end
end

return CoverMenu
