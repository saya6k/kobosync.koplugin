-- Server library browser: lists the synced catalog, downloads a book on tap
-- (when not yet on the device) and opens it in the reader.
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

local function item_text(book)
    if book.author and book.author ~= "" then
        return book.title .. " – " .. book.author
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

local function build_items(plugin, menu)
    local books = plugin:getState():list_books()
    -- Newest on the server first.
    table.sort(books, function(a, b)
        return (a.last_modified or "") > (b.last_modified or "")
    end)
    local items = {}
    for _idx, book in ipairs(books) do
        table.insert(items, {
            text = item_text(book),
            mandatory = item_mandatory(book),
            callback = function()
                Browser.openBook(plugin, menu, book)
            end,
        })
    end
    return items
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
    }
    menu.item_table = build_items(plugin, menu)
    menu.subtitle = T(_("%1 books"), #menu.item_table)
    UIManager:show(menu)
    menu:switchItemTable(menu.title, menu.item_table, 1, nil, menu.subtitle)
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
