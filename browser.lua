-- Server library browser: lists the synced catalog grouped by series, downloads
-- a book on tap (when not yet on the device) and opens it in the reader.
local ButtonDialog = require("ui/widget/buttondialog")
local InfoMessage = require("ui/widget/infomessage")
local ImageViewer = require("ui/widget/imageviewer")
local InputDialog = require("ui/widget/inputdialog")
local CoverMenu = require("covermenu")
local Menu = require("ui/widget/menu")
local NetworkMgr = require("ui/network/manager")
local UIManager = require("ui/uimanager")
local lfs = require("libs/libkoreader-lfs")
local util = require("util")
local _ = require("gettext")
local T = require("ffi/util").template

local SyncEngine = require("syncengine")

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

local function book_item(plugin, menu, book, text)
    return {
        text = text,
        mandatory = item_mandatory(book),
        -- Read back by onMenuHold, which only receives the item table entry.
        kobosync_book = book,
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
    for _, book in ipairs(group.books) do
        table.insert(items, book_item(plugin, menu, book,
            SyncEngine.short_title(book.title, group.name)))
    end
    menu:switchItemTable(group.name, items, 1, nil,
        T(_("%1 books"), #items) .. filter_note(menu))
end

-- Search results are flat: grouping a handful of hits behind series rows would
-- just add a tap. Ordering still comes from the grouper, so chapters of one
-- series stay together and in number order.
local function show_search_results(plugin, menu)
    local groups, standalone = SyncEngine.group_by_series(visible_books(plugin, menu))
    local items = {}
    for _, group in ipairs(groups) do
        for _, book in ipairs(group.books) do
            table.insert(items, book_item(plugin, menu, book,
                group.name .. " · " .. SyncEngine.short_title(book.title, group.name)))
        end
    end
    for _, book in ipairs(standalone) do
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
    for _, group in ipairs(groups) do
        total = total + #group.books
        table.insert(items, {
            text = group.name,
            mandatory = string.format("%d/%d", group.downloaded, #group.books),
            -- Hold on a series shows the first chapter's cover.
            kobosync_book = group.books[1],
            callback = function()
                show_series(plugin, menu, group)
            end,
        })
    end
    for _, book in ipairs(standalone) do
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

local function show_filter_menu(plugin, menu)
    local dialog
    local downloaded_label = menu.kobosync_downloaded_only
        and _("Show all books") or _("Show downloaded only")
    -- A tick marks the mode in force; tapping a row switches to it.
    local function mode_label(mode, label)
        return (plugin.cover_mode == mode and "✓ " or "") .. label
    end
    dialog = ButtonDialog:new{
        buttons = {
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
                text = mode_label("list", _("Cover list")),
                callback = function()
                    UIManager:close(dialog)
                    switch_cover_mode(plugin, menu, "list")
                end,
            }},
            {{
                text = mode_label("grid", _("Cover grid")),
                callback = function()
                    UIManager:close(dialog)
                    switch_cover_mode(plugin, menu, "grid")
                end,
            }},
        },
    }
    UIManager:show(dialog)
end

function Browser.show(plugin)
    local menu
    -- Covers need a row widget KOReader's Menu cannot provide; see covermenu.lua.
    local with_covers = plugin.cover_mode == "list" or plugin.cover_mode == "grid"
    local class = with_covers and CoverMenu or Menu
    local tried_covers = {}
    menu = class:new{
        kobosync_grid = plugin.cover_mode == "grid",
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
        Browser.showCover(plugin, item and item.kobosync_book)
        return true
    end
    UIManager:show(menu)
    show_top(plugin, menu)
end

-- Hold on a row: fetch the server-side cover and show it. Covers only exist for
-- books synced since the plugin started recording CoverImageId.
function Browser.showCover(plugin, book)
    if not book then return end
    NetworkMgr:runWhenOnline(function()
        local info = InfoMessage:new{ text = _("Kobo Sync: fetching cover…") }
        UIManager:show(info)
        UIManager:forceRePaint()
        local path, err = plugin:fetchCover(plugin:getApi(), book)
        UIManager:close(info)
        if not path then
            UIManager:show(InfoMessage:new{
                text = T(_("Kobo Sync: no cover (%1)"), err or _("unknown error")),
            })
            return
        end
        UIManager:show(ImageViewer:new{
            file = path,
            fullscreen = true,
            with_title_bar = true,
            title_text = book.title or "",
        })
    end)
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
