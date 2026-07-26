-- Server library browser: lists the synced catalog grouped by series, downloads
-- a book on tap (when not yet on the device) and opens it in the reader.
local ButtonDialog = require("ui/widget/buttondialog")
local ConfirmBox = require("ui/widget/confirmbox")
local InfoMessage = require("ui/widget/infomessage")
local InputDialog = require("ui/widget/inputdialog")
local CoverMenu = require("kobosync_covermenu")
local Menu = require("ui/widget/menu")
local NetworkMgr = require("ui/network/manager")
local Trapper = require("ui/trapper")
local UIManager = require("ui/uimanager")
local lfs = require("libs/libkoreader-lfs")
local util = require("util")
local _ = require("kobosync_gettext")
local T = require("ffi/util").template

local SyncEngine = require("kobosync_syncengine")

local Browser = {}

local function standalone_text(book)
    if book.author and book.author ~= "" then
        return (book.title or book.uuid) .. " – " .. book.author
    end
    return book.title or book.uuid
end

local function item_mandatory(book)
    if book.downloaded then
        return "✓"
    end
    local pick = SyncEngine.pick_download(book.download_urls)
    if pick and pick.Size then
        return util.getFriendlySize(pick.Size)
    end
    return ""
end

-- `group` is the series the book belongs to, when it has one. Both fields are
-- read back by onMenuHold, which only receives the item table entry.
local function book_item(plugin, menu, book, text, group)
    return {
        text = text,
        mandatory = item_mandatory(book),
        kobosync_book = book,
        kobosync_group = group,
        callback = function()
            Browser.openBook(plugin, menu, book)
        end,
    }
end

-- The catalog as the current search/filter selection sees it.
local function visible_books(plugin, menu)
    return SyncEngine.filter_books(plugin:getState():list_books(), {
        query = menu.kobosync_query,
        downloaded_only = menu.kobosync_downloaded_only,
    })
end

local function filter_note(menu)
    if menu.kobosync_downloaded_only then
        return " " .. _("(downloaded only)")
    end
    return ""
end

local show_top

-- Second level: the chapters of one series, oldest number first, with the
-- series name stripped off each title.
local function show_series(plugin, menu, group)
    table.insert(menu.paths, group.name)
    local items = {}
    -- Above the first chapter, so the whole series can be taken without
    -- hunting for the hold gesture.
    local pending = SyncEngine.plan_books(group.books)
    if #pending > 0 then
        table.insert(items, {
            text = T(_("Download all %1 books"), #pending),
            mandatory = util.getFriendlySize(SyncEngine.plan_size(pending)),
            callback = function()
                Browser.downloadBooks(plugin, menu, group.books, group.name, function()
                    -- Back to this series, not the top: that is where the user is.
                    table.remove(menu.paths)
                    show_series(plugin, menu, group)
                end)
            end,
        })
    end
    for _idx, book in ipairs(group.books) do
        table.insert(items, book_item(plugin, menu, book,
            SyncEngine.short_title(book.title, group.name), group))
    end
    menu:switchItemTable(group.name, items, 1, nil,
        T(_("%1 books"), #group.books) .. filter_note(menu))
end

-- Search results are flat: grouping a handful of hits behind series rows would
-- just add a tap. Ordering still comes from the grouper, so chapters of one
-- series stay together and in number order.
local function show_search_results(plugin, menu)
    local groups, standalone = SyncEngine.group_by_series(visible_books(plugin, menu))
    local items = {}
    for _gidx, group in ipairs(groups) do
        for _bidx, book in ipairs(group.books) do
            table.insert(items, book_item(plugin, menu, book,
                group.name .. " · " .. SyncEngine.short_title(book.title, group.name), group))
        end
    end
    for _idx, book in ipairs(standalone) do
        table.insert(items, book_item(plugin, menu, book, standalone_text(book)))
    end
    -- Non-empty paths is what enables Menu's return arrow.
    menu.paths = { menu.kobosync_query }
    menu:switchItemTable(T(_("Search: %1"), menu.kobosync_query), items, 1, nil,
        T(_("%1 books"), #items) .. filter_note(menu))
end

-- Top level: one row per series (with a downloaded/total count), then the books
-- that belong to no series.
local function show_series_list(plugin, menu)
    menu.paths = {}
    local groups, standalone = SyncEngine.group_by_series(visible_books(plugin, menu))
    local items = {}
    local total = #standalone
    for _idx, group in ipairs(groups) do
        total = total + #group.books
        table.insert(items, {
            text = group.name,
            mandatory = string.format("%d/%d", group.downloaded, #group.books),
            -- Held to download the whole series; see onMenuHold.
            kobosync_group = group,
            callback = function()
                show_series(plugin, menu, group)
            end,
        })
    end
    for _idx, book in ipairs(standalone) do
        table.insert(items, book_item(plugin, menu, book, standalone_text(book)))
    end
    menu:switchItemTable(_("Kobo Sync library"), items, 1, nil,
        T(_("%1 series, %2 books"), #groups, total) .. filter_note(menu))
end

show_top = function(plugin, menu)
    if menu.kobosync_query then
        show_search_results(plugin, menu)
    else
        show_series_list(plugin, menu)
    end
end

local function show_search_dialog(plugin, menu)
    local dialog
    dialog = InputDialog:new{
        title = _("Search the server library"),
        input = menu.kobosync_query or "",
        description = _("Matches book titles and series names."),
        buttons = {{
            {
                text = _("Cancel"),
                id = "close",
                callback = function() UIManager:close(dialog) end,
            },
            {
                text = _("Search"),
                is_enter_default = true,
                callback = function()
                    local query = dialog:getInputText()
                    UIManager:close(dialog)
                    menu.kobosync_query = query ~= "" and query or nil
                    show_top(plugin, menu)
                end,
            },
        }},
    }
    UIManager:show(dialog)
    dialog:onShowKeyboard()
end

-- The row widget differs per mode, so the browser is rebuilt rather than
-- repainted.
local function switch_cover_mode(plugin, menu, mode)
    if plugin.cover_mode == mode then return end
    plugin:setCoverMode(mode)
    UIManager:close(menu)
    Browser.show(plugin)
end

-- Column counts worth offering: fewer than two is the list mode, more than
-- five leaves covers smaller than the list mode already gave.
local GRID_COL_CHOICES = { 2, 3, 4, 5 }

local function show_grid_cols_menu(plugin, menu)
    local dialog
    local buttons = {}
    for _idx, cols in ipairs(GRID_COL_CHOICES) do
        table.insert(buttons, {{
            text = (plugin.grid_cols == cols and "✓ " or "") .. T(_("%1 columns"), cols),
            callback = function()
                UIManager:close(dialog)
                if plugin.grid_cols ~= cols then
                    plugin:setGridCols(cols)
                    UIManager:close(menu)
                    Browser.show(plugin)
                end
            end,
        }})
    end
    dialog = ButtonDialog:new{ buttons = buttons }
    UIManager:show(dialog)
end

local function show_filter_menu(plugin, menu)
    local dialog
    local downloaded_label = menu.kobosync_downloaded_only
        and _("Show all books") or _("Show downloaded only")
    -- A tick marks the mode in force; tapping a row switches to it.
    local function mode_label(mode, label)
        return (plugin.cover_mode == mode and "✓ " or "") .. label
    end
    local buttons = {
        {{
            text = _("Search…"),
            callback = function()
                UIManager:close(dialog)
                show_search_dialog(plugin, menu)
            end,
        }},
        {{
            text = downloaded_label,
            callback = function()
                UIManager:close(dialog)
                menu.kobosync_downloaded_only = not menu.kobosync_downloaded_only
                show_top(plugin, menu)
            end,
        }},
        {{
            text = mode_label("off", _("Text list")),
            callback = function()
                UIManager:close(dialog)
                switch_cover_mode(plugin, menu, "off")
            end,
        }},
        {{
            text = mode_label("grid", _("Cover grid")),
            callback = function()
                UIManager:close(dialog)
                switch_cover_mode(plugin, menu, "grid")
            end,
        }},
    }
    -- Only meaningful in grid mode, so it is not shown otherwise. The list has
    -- to be complete before the dialog is built: ButtonDialog lays its buttons
    -- out in init, and appending afterwards would not show up.
    if plugin.cover_mode == "grid" then
        table.insert(buttons, {{
            text = T(_("Grid columns: %1"), plugin.grid_cols),
            callback = function()
                UIManager:close(dialog)
                show_grid_cols_menu(plugin, menu)
            end,
        }})
    end
    dialog = ButtonDialog:new{ buttons = buttons }
    UIManager:show(dialog)
end

function Browser.show(plugin)
    local menu
    -- Covers need a row widget KOReader's Menu cannot provide; see covermenu.lua.
    local with_covers = plugin.cover_mode == "grid"
    local class = with_covers and CoverMenu or Menu
    local tried_covers = {}
    menu = class:new{
        kobosync_grid_cols = plugin.grid_cols,
        title = _("Kobo Sync library"),
        subtitle = "",
        item_table = {},
        is_borderless = true,
        is_popout = false,
        title_bar_fm_style = true,
        title_bar_left_icon = "appbar.menu",
        -- Menu shows its return arrow whenever onReturn is set, and enables it
        -- while paths is non-empty. Search results are flat and a series has no
        -- deeper level, so one step always lands back on the series list.
        onReturn = function()
            menu.kobosync_query = nil
            show_top(plugin, menu)
        end,
    }
    if with_covers then
        menu.cover_file_func = function(item)
            return plugin:cachedCoverPath(item.kobosync_book)
        end
        menu.fetch_cover_func = function(item)
            local book = item.kobosync_book
            if not book or not book.cover_id or tried_covers[book.cover_id] then
                return false
            end
            tried_covers[book.cover_id] = true
            return plugin:fetchCover(plugin:getApi(), book) ~= nil
        end
    end
    menu.onLeftButtonTap = function()
        show_filter_menu(plugin, menu)
    end
    menu.onMenuHold = function(_self, item)
        if not item then return true end
        local group = item.kobosync_group
        if group then
            Browser.downloadBooks(plugin, menu, group.books, group.name,
                function() show_top(plugin, menu) end)
        elseif item.kobosync_book then
            -- A book outside any series: the row stands only for itself.
            local book = item.kobosync_book
            Browser.downloadBooks(plugin, menu, { book }, book.title or "",
                function() show_top(plugin, menu) end)
        end
        return true
    end
    UIManager:show(menu)
    show_top(plugin, menu)
end

-- Downloads a set of books chosen by hand -- a whole series, or the one book a
-- row stands for when it belongs to none. The download mode is not consulted:
-- asking for these is the decision it would otherwise be making.
function Browser.downloadBooks(plugin, menu, books, label, refresh)
    local plan = SyncEngine.plan_books(books)
    if #plan == 0 then
        UIManager:show(InfoMessage:new{
            text = T(_("Kobo Sync: “%1” is already on this device."), label),
        })
        return
    end
    UIManager:show(ConfirmBox:new{
        text = T(_("Kobo Sync: download %1 book(s) from “%2”?\n\n%3"),
            #plan, label, util.getFriendlySize(SyncEngine.plan_size(plan))),
        ok_text = _("Download"),
        ok_callback = function()
            NetworkMgr:runWhenOnline(function()
                Trapper:wrap(function()
                    local state = plugin:getState()
                    local downloaded, failed =
                        plugin:downloadPlanned(state, plugin:getApi(), plan)
                    state:save()
                    local text = T(_("Kobo Sync: %1 downloaded."), downloaded)
                    if failed > 0 then
                        text = text .. "\n" .. T(_("Failed: %1"), failed)
                    end
                    UIManager:show(InfoMessage:new{ text = text })
                    -- Redraw so the ticks and the series counts catch up.
                    if refresh then refresh() end
                end)
            end)
        end,
    })
end

function Browser.openBook(plugin, menu, book)
    local state = plugin:getState()
    local current = state:get_book(book.uuid) or book
    if current.downloaded and current.local_path
            and lfs.attributes(current.local_path, "mode") == "file" then
        UIManager:close(menu)
        local ReaderUI = require("apps/reader/readerui")
        ReaderUI:showReader(current.local_path)
        return
    end
    local pick = SyncEngine.pick_download(current.download_urls)
    if not pick then
        UIManager:show(InfoMessage:new{
            text = _("Kobo Sync: no downloadable format for this book."),
        })
        return
    end
    NetworkMgr:runWhenOnline(function()
        local info = InfoMessage:new{
            text = T(_("Kobo Sync: downloading\n%1"), current.title or ""),
        }
        UIManager:show(info)
        UIManager:forceRePaint()
        local ok, err = plugin:downloadBook(state, plugin:getApi(), {
            uuid = book.uuid,
            title = current.title,
            url = pick.Url,
            format = pick.Format,
            size = pick.Size,
            revision_id = current.revision_id,
        })
        state:save()
        UIManager:close(info)
        if not ok then
            UIManager:show(InfoMessage:new{
                text = T(_("Kobo Sync: download failed: %1"), err or ""),
            })
            return
        end
        UIManager:close(menu)
        local ReaderUI = require("apps/reader/readerui")
        ReaderUI:showReader(state:get_book(book.uuid).local_path)
    end)
end

return Browser
