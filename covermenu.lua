-- Menu whose rows carry a cover thumbnail.
--
-- KOReader's Menu hardcodes MenuItem when it builds a row (the MenuItem:new
-- call inside Menu:updateItems) and MenuItem composes text widgets only, so
-- there is no hook for a per-row image. The bundled CoverBrowser plugin works
-- around this by replacing FileChooser.updateItems wholesale; the same is done
-- here, except scoped to this subclass so nothing global is patched.
--
-- The consequence is that this file mirrors the shape of Menu:updateItems as of
-- KOReader v2026.03 and will drift if that method's contract changes. Cover
-- rows are therefore opt-in, and any error while building them falls back to
-- the stock rendering for the rest of the session.

local CenterContainer = require("ui/widget/container/centercontainer")
local Font = require("ui/font")
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local HorizontalSpan = require("ui/widget/horizontalspan")
local ImageWidget = require("ui/widget/imagewidget")
local InputContainer = require("ui/widget/container/inputcontainer")
local LeftContainer = require("ui/widget/container/leftcontainer")
local Menu = require("ui/widget/menu")
local RightContainer = require("ui/widget/container/rightcontainer")
local Size = require("ui/size")
local TextWidget = require("ui/widget/textwidget")
local UIManager = require("ui/uimanager")
local logger = require("logger")

-- Covers are 2:3; the box is reserved whether or not the image has been
-- fetched, so rows do not jump around as covers arrive.
local COVER_ASPECT_W, COVER_ASPECT_H = 2, 3

local CoverMenuItem = InputContainer:extend{
    entry = nil,
    cover_file = nil,
    menu = nil,
    font_size = 18,
}

function CoverMenuItem:init()
    self.ges_events = {
        TapSelect = {
            GestureRange:new{ ges = "tap", range = self.dimen },
        },
        HoldSelect = {
            GestureRange:new{ ges = "hold", range = self.dimen },
        },
    }

    local padding = Size.padding.default
    local inner_h = self.dimen.h - 2 * padding
    local cover_w = math.floor(inner_h * COVER_ASPECT_W / COVER_ASPECT_H)

    local cover
    if self.cover_file then
        cover = ImageWidget:new{
            file = self.cover_file,
            width = cover_w,
            height = inner_h,
            scale_factor = 0, -- fit inside the box, keeping the image's ratio
        }
    else
        cover = HorizontalSpan:new{ width = cover_w }
    end

    local face = Font:getFace("cfont", self.font_size)
    local info_face = Font:getFace("infont", self.font_size - 4)

    local mandatory_widget
    local mandatory_w = 0
    if self.mandatory and self.mandatory ~= "" then
        mandatory_widget = TextWidget:new{ text = self.mandatory, face = info_face }
        mandatory_w = mandatory_widget:getWidth() + padding
    end

    local text_w = self.dimen.w - cover_w - mandatory_w - 4 * padding
    local text_widget = TextWidget:new{
        text = self.text or "",
        face = face,
        max_width = text_w,
    }

    local row = HorizontalGroup:new{
        HorizontalSpan:new{ width = padding },
        CenterContainer:new{
            dimen = Geom:new{ w = cover_w, h = inner_h },
            cover,
        },
        HorizontalSpan:new{ width = padding },
        LeftContainer:new{
            dimen = Geom:new{ w = text_w, h = inner_h },
            text_widget,
        },
    }
    if mandatory_widget then
        table.insert(row, RightContainer:new{
            dimen = Geom:new{ w = mandatory_w, h = inner_h },
            mandatory_widget,
        })
    end

    self[1] = CenterContainer:new{
        dimen = self.dimen:copy(),
        row,
    }
end

function CoverMenuItem:onTapSelect()
    if self.entry and self.entry.callback then
        self.entry.callback()
    end
    return true
end

function CoverMenuItem:onHoldSelect()
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
}

-- Mirrors Menu:updateItems, swapping MenuItem for a row with a thumbnail.
-- Shortcuts and the items_max_lines layout are not reproduced: this menu uses
-- neither.
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
        local widget = CoverMenuItem:new{
            text = self.getMenuText and self.getMenuText(item) or item.text,
            mandatory = item.mandatory,
            entry = item,
            cover_file = cover_file,
            menu = self,
            font_size = self.font_size,
            dimen = self.item_dimen:copy(),
            show_parent = self.show_parent,
        }
        table.insert(self.item_group, widget)
        table.insert(self.layout, { widget })
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
    local ok, err = pcall(self._buildCoverItems, self, select_number, no_recalculate_dimen)
    if not ok then
        logger.warn("KoboSync: cover rows failed, falling back to the plain list:", err)
        self.kobosync_covers_broken = true
        return Menu.updateItems(self, select_number, no_recalculate_dimen)
    end
end

return CoverMenu
