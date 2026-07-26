-- Server library browser: lists the synced catalog grouped by series, downloads
-- a book on tap (when not yet on the device) and opens it in the reader.
local InfoMessage = require("ui/widget/infomessage")
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
        callback = function()
            Browser.openBook(plugin, menu, book)
        end,
    }
end

local show_series_list

-- Second level: the chapters of one series, oldest number first, with the
-- series name stripped off each title.
local function show_series(plugin, menu, group)
    table.insert(menu.paths, group.name)
    local items = {}
    for _, book in ipairs(group.books) do
        table.insert(items, book_item(plugin, menu, book,
            SyncEngine.short_title(book.title, group.name)))
    end
    menu:switchItemTable(group.name, items, 1, nil, T(_("%1 books"), #items))
end

-- Top level: one row per series (with a downloaded/total count), then the books
-- that belong to no series.
show_series_list = function(plugin, menu)
    menu.paths = {}
    local groups, standalone = SyncEngine.group_by_series(plugin:getState():list_books())
    local items = {}
    local total = #standalone
    for _, group in ipairs(groups) do
        total = total + #group.books
        table.insert(items, {
            text = group.name,
            mandatory = string.format("%d/%d", group.downloaded, #group.books),
            callback = function()
                show_series(plugin, menu, group)
            end,
        })
    end
    for _, book in ipairs(standalone) do
        table.insert(items, book_item(plugin, menu, book, standalone_text(book)))
    end
    menu:switchItemTable(_("Kobo Sync library"), items, 1, nil,
        T(_("%1 series, %2 books"), #groups, total))
end

function Browser.show(plugin)
    local menu
    menu = Menu:new{
        title = _("Kobo Sync library"),
        subtitle = "",
        item_table = {},
        is_borderless = true,
        is_popout = false,
        title_bar_fm_style = true,
        -- Menu shows its return arrow whenever onReturn is set, and enables it
        -- while paths is non-empty -- so this is the way back out of a series.
        onReturn = function()
            show_series_list(plugin, menu)
        end,
    }
    UIManager:show(menu)
    show_series_list(plugin, menu)
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
