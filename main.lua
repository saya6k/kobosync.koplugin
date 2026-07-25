local ConfirmBox = require("ui/widget/confirmbox")
local DataStorage = require("datastorage")
local Dispatcher = require("dispatcher")
local DocSettings = require("docsettings")
local DownloadMgr = require("ui/downloadmgr")
local InfoMessage = require("ui/widget/infomessage")
local InputDialog = require("ui/widget/inputdialog")
local LuaSettings = require("luasettings")
local NetworkMgr = require("ui/network/manager")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local http = require("socket.http")
local lfs = require("libs/libkoreader-lfs")
local logger = require("logger")
local ltn12 = require("ltn12")
local rapidjson = require("rapidjson")
local socket = require("socket")
local socketutil = require("socketutil")
local _ = require("gettext")
local T = require("ffi/util").template

local KoboApi = require("koboapi")
local StateStore = require("statestore")
local SyncEngine = require("syncengine")

local KoboSync = WidgetContainer:extend{
    name = "kobosync",
    is_doc_only = false,
}

-- HTTP implementation injected into KoboApi (see koboapi.lua for the shape).
local function http_request(req)
    local pieces = {}
    local request = {
        url = req.url,
        method = req.method,
        headers = req.headers or {},
        sink = req.sink or ltn12.sink.table(pieces),
    }
    if req.body then
        request.source = ltn12.source.string(req.body)
        request.headers["Content-Length"] = tostring(#req.body)
    end
    if req.sink then
        socketutil:set_timeout(socketutil.FILE_BLOCK_TIMEOUT, socketutil.FILE_TOTAL_TIMEOUT)
    else
        socketutil:set_timeout(socketutil.LARGE_BLOCK_TIMEOUT, socketutil.LARGE_TOTAL_TIMEOUT)
    end
    local code, headers, status = socket.skip(1, http.request(request))
    socketutil:reset_timeout()
    if headers == nil or type(code) ~= "number" then
        logger.warn("KoboSync: network error:", status or code)
        return nil, tostring(status or code or "network error")
    end
    return { code = code, headers = headers, body = table.concat(pieces) }
end

function KoboSync:init()
    self.settings = LuaSettings:open(DataStorage:getSettingsDir() .. "/kobosync.lua")
    self.server_url = self.settings:readSetting("server_url")
    self.download_dir = self.settings:readSetting("download_dir")
        or DataStorage:getDataDir() .. "/kobosync"
    self.download_mode = self.settings:readSetting("download_mode") or "auto"
    self:onDispatcherRegisterActions()
    self.ui.menu:registerToMainMenu(self)
end

function KoboSync:onDispatcherRegisterActions()
    Dispatcher:registerAction("kobosync_sync", {
        category = "none",
        event = "KoboSyncSync",
        title = _("Kobo Sync: synchronize"),
        general = true,
    })
end

function KoboSync:saveSettings()
    self.settings:saveSetting("server_url", self.server_url)
    self.settings:saveSetting("download_dir", self.download_dir)
    self.settings:saveSetting("download_mode", self.download_mode)
    self.settings:flush()
end

function KoboSync:getState()
    if not self.state then
        self.state = StateStore.new{
            path = DataStorage:getSettingsDir() .. "/kobosync_state.json",
            json = rapidjson,
        }
    end
    return self.state
end

function KoboSync:getApi()
    return KoboApi.new{
        base_url = self.server_url,
        request = http_request,
        json = rapidjson,
    }
end

function KoboSync:addToMainMenu(menu_items)
    menu_items.kobosync = {
        text = _("Kobo Sync"),
        sorting_hint = "tools",
        sub_item_table = {
            {
                text = _("Synchronize now"),
                enabled_func = function() return self.server_url ~= nil end,
                callback = function() self:onKoboSyncSync() end,
            },
            {
                text_func = function()
                    return self.server_url
                        and T(_("Server: %1"), self.server_url)
                        or _("Set server URL")
                end,
                keep_menu_open = true,
                callback = function() self:showServerDialog() end,
                separator = true,
            },
            {
                text_func = function()
                    return T(_("Download folder: %1"), self.download_dir)
                end,
                keep_menu_open = true,
                callback = function()
                    DownloadMgr:new{
                        onConfirm = function(path)
                            self.download_dir = path
                            self:saveSettings()
                        end,
                    }:chooseDir(self.download_dir)
                end,
            },
        },
    }
end

function KoboSync:showServerDialog()
    local dialog
    dialog = InputDialog:new{
        title = _("Kobo Sync server URL"),
        input = self.server_url or "",
        input_hint = "https://server/kobo/auth_token",
        description = _("Full Kobo Sync prefix including the personal token, "
            .. "as shown by your server (calibre-web: Profile → Kobo Sync Token)."),
        buttons = {{
            {
                text = _("Cancel"),
                id = "close",
                callback = function() UIManager:close(dialog) end,
            },
            {
                text = _("Save"),
                is_enter_default = true,
                callback = function()
                    local url = dialog:getInputText():gsub("%s+", ""):gsub("/+$", "")
                    self.server_url = url ~= "" and url or nil
                    self:saveSettings()
                    UIManager:close(dialog)
                end,
            },
        }},
    }
    UIManager:show(dialog)
    dialog:onShowKeyboard()
end

function KoboSync:onKoboSyncSync()
    if not self.server_url then
        UIManager:show(InfoMessage:new{ text = _("Kobo Sync: set the server URL first.") })
        return true
    end
    NetworkMgr:runWhenOnline(function() self:doSync() end)
    return true
end

function KoboSync:doSync()
    local info = InfoMessage:new{ text = _("Kobo Sync: synchronizing…") }
    UIManager:show(info)
    UIManager:forceRePaint()

    local state = self:getState()
    local api = self:getApi()
    local result = SyncEngine.new_result()
    local token, err, partial_token = api:sync(state:get_synctoken(), function(items)
        SyncEngine.process_items(state, items, result)
    end)
    -- Keep progress from already processed pages even on a failed run.
    state:set_synctoken(token or partial_token or state:get_synctoken())
    state:save()
    UIManager:close(info)
    if not token then
        UIManager:show(InfoMessage:new{
            text = T(_("Kobo Sync failed: %1"), err or _("unknown error")),
        })
        return
    end

    local downloaded, failed = self:downloadPlanned(state, api)
    state:save()

    self:confirmDeletions(state, result.delete_candidates, function()
        local lines = {
            T(_("Kobo Sync finished.\nNew: %1  Changed: %2"), result.new, result.changed),
        }
        if downloaded > 0 then
            table.insert(lines, T(_("Downloaded: %1"), downloaded))
        end
        if failed > 0 then
            table.insert(lines, T(_("Failed downloads: %1"), failed))
        end
        UIManager:show(InfoMessage:new{ text = table.concat(lines, "\n") })
    end)
end

function KoboSync:downloadPlanned(state, api)
    local plan = SyncEngine.plan_downloads(state, self.download_mode)
    if #plan == 0 then return 0, 0 end
    if lfs.attributes(self.download_dir, "mode") ~= "directory" then
        lfs.mkdir(self.download_dir)
    end
    local downloaded, failed = 0, 0
    for i, item in ipairs(plan) do
        local info = InfoMessage:new{
            text = T(_("Kobo Sync: downloading %1 of %2\n%3"), i, #plan, item.title or ""),
        }
        UIManager:show(info)
        UIManager:forceRePaint()
        local ok, dl_err = self:downloadBook(state, api, item)
        UIManager:close(info)
        if ok then
            downloaded = downloaded + 1
        else
            failed = failed + 1
            logger.warn("KoboSync: download failed:", item.uuid, dl_err)
        end
    end
    return downloaded, failed
end

function KoboSync:downloadBook(state, api, item)
    local book = state:get_book(item.uuid)
    if not book then return nil, "not in catalog" end
    local base = SyncEngine.sanitize_filename(book.title, book.author)
    local ext = SyncEngine.extension_for(item.format)
    local filename = SyncEngine.unique_filename(base, ext, item.uuid, function(name)
        -- Taken if the file exists but is not this book's own file.
        local path = self.download_dir .. "/" .. name
        if not lfs.attributes(path, "mode") then return false end
        return book.local_path ~= path
    end)
    local path = self.download_dir .. "/" .. filename
    local tmp_path = path .. ".kobosync.tmp"
    local file, io_err = io.open(tmp_path, "w")
    if not file then return nil, io_err end
    local ok, dl_err = api:download(item.url, ltn12.sink.file(file))
    if not ok then
        os.remove(tmp_path)
        return nil, dl_err
    end
    local renamed, mv_err = os.rename(tmp_path, path)
    if not renamed then
        os.remove(tmp_path)
        return nil, mv_err
    end
    state:upsert_book(item.uuid, {
        downloaded = true,
        local_path = path,
        downloaded_revision = item.revision_id,
        downloaded_size = item.size,
    })
    return true
end

-- Asks the user before deleting local files of server-removed books, then
-- calls done_callback() regardless of the choice.
function KoboSync:confirmDeletions(state, candidates, done_callback)
    if #candidates == 0 then
        done_callback()
        return
    end
    local titles = {}
    for i, c in ipairs(candidates) do
        if i > 10 then
            table.insert(titles, T(_("…and %1 more"), #candidates - 10))
            break
        end
        table.insert(titles, "• " .. (c.title or c.uuid))
    end
    UIManager:show(ConfirmBox:new{
        text = T(_("Kobo Sync: %1 book(s) were removed on the server. Delete the local files?\n\n%2"),
            #candidates, table.concat(titles, "\n")),
        ok_text = _("Delete"),
        ok_callback = function()
            for _idx, c in ipairs(candidates) do
                if c.local_path then
                    os.remove(c.local_path)
                    pcall(function()
                        DocSettings:open(c.local_path):purge()
                    end)
                end
                state:remove_book(c.uuid)
            end
            state:save()
            done_callback()
        end,
        cancel_text = _("Keep"),
        cancel_callback = function()
            -- Keep files; drop catalog entries so they are not asked again.
            for _idx, c in ipairs(candidates) do
                state:remove_book(c.uuid)
            end
            state:save()
            done_callback()
        end,
    })
end

return KoboSync
