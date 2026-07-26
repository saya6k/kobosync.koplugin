local ConfirmBox = require("ui/widget/confirmbox")
local DataStorage = require("datastorage")
local Dispatcher = require("dispatcher")
local DocSettings = require("docsettings")
local DownloadMgr = require("ui/downloadmgr")
local InfoMessage = require("ui/widget/infomessage")
local InputDialog = require("ui/widget/inputdialog")
local LuaSettings = require("luasettings")
local NetworkMgr = require("ui/network/manager")
local Trapper = require("ui/trapper")
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

local Event = require("ui/event")

local KoboApi = require("koboapi")
local ReadingState = require("readingstate")
local StateStore = require("statestore")
local SyncEngine = require("syncengine")

-- Ask before bulk downloads (first sync, or mass changes later).
local BULK_CONFIRM_THRESHOLD = 10

local KoboSync = WidgetContainer:extend{
    name = "kobosync",
    is_doc_only = false,
}

-- socketutil's LARGE_* pair (10s block) is too tight for /v1/library/sync: the
-- server builds the whole page before sending anything, which on a large
-- library takes over ten seconds of silence on the socket. LuaSec reports that
-- as "wantread" rather than a timeout, so the sync just fails.
local API_BLOCK_TIMEOUT = 30
local API_TOTAL_TIMEOUT = 120

-- LuaSocket/LuaSec surface timeouts as opaque codes; say what they mean.
local function describe_error(status)
    if status == socketutil.TIMEOUT_CODE
        or status == socketutil.SSL_HANDSHAKE_CODE
        or status == socketutil.SINK_TIMEOUT_CODE then
        return _("the server took too long to respond")
    end
    return tostring(status or "network error")
end

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
        socketutil:set_timeout(API_BLOCK_TIMEOUT, API_TOTAL_TIMEOUT)
    end
    local code, headers, status = socket.skip(1, http.request(request))
    socketutil:reset_timeout()
    if headers == nil or type(code) ~= "number" then
        logger.warn("KoboSync: network error:", status or code)
        return nil, describe_error(status or code)
    end
    return { code = code, headers = headers, body = table.concat(pieces) }
end

function KoboSync:init()
    self.settings = LuaSettings:open(DataStorage:getSettingsDir() .. "/kobosync.lua")
    self.server_url = self.settings:readSetting("server_url")
    self.download_dir = self.settings:readSetting("download_dir")
        or DataStorage:getDataDir() .. "/kobosync"
    self.download_mode = self.settings:readSetting("download_mode") or "auto"
    self.upload_on_close = self.settings:nilOrTrue("upload_on_close")
    self.image_url_template = self.settings:readSetting("image_url_template")
    -- "off" | "list" | "grid". Migrated from the earlier boolean setting.
    self.cover_mode = self.settings:readSetting("cover_mode")
        or (self.settings:isTrue("show_covers") and "list" or "off")
    self.grid_cols = tonumber(self.settings:readSetting("grid_cols")) or 3
    self.cover_dir = DataStorage:getDataDir() .. "/cache/kobosync"
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
    self.settings:saveSetting("upload_on_close", self.upload_on_close)
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
        sleep = socket.sleep,
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
                text = _("Browse server library"),
                enabled_func = function() return self.server_url ~= nil end,
                callback = function()
                    local Browser = require("browser")
                    Browser.show(self)
                end,
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
            {
                text = _("Download new books automatically"),
                help_text = _("When disabled, syncing only updates the catalog; "
                    .. "download books individually from the server library browser."),
                checked_func = function() return self.download_mode == "auto" end,
                callback = function()
                    self.download_mode = self.download_mode == "auto" and "on_demand" or "auto"
                    self:saveSettings()
                end,
            },
            {
                text = _("Upload reading progress when closing a book"),
                checked_func = function() return self.upload_on_close end,
                callback = function()
                    self.upload_on_close = not self.upload_on_close
                    self:saveSettings()
                end,
                separator = true,
            },
            {
                text = _("Reset sync"),
                keep_menu_open = true,
                callback = function()
                    UIManager:show(ConfirmBox:new{
                        text = _("Kobo Sync: forget the sync state and catalog?\n"
                            .. "Downloaded files are kept. The next synchronization "
                            .. "will be a full one."),
                        ok_text = _("Reset"),
                        ok_callback = function()
                            local state = self:getState()
                            state:reset()
                            state:save()
                            UIManager:show(InfoMessage:new{ text = _("Kobo Sync: state reset.") })
                        end,
                    })
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
    NetworkMgr:runWhenOnline(function()
        Trapper:wrap(function() self:doSync() end)
    end)
    return true
end

function KoboSync:doSync()
    Trapper:info(_("Kobo Sync: synchronizing…"))

    local state = self:getState()
    local api = self:getApi()
    local first_sync = state:get_synctoken() == nil
    local result = SyncEngine.new_result()
    local seen, cancelled = 0, false
    local token, err, partial_token = api:sync(state:get_synctoken(), function(items, page)
        SyncEngine.process_items(state, items, result)
        seen = seen + #items
        -- The protocol sends no total, so this counts up instead of filling a
        -- bar. Trapper:info also yields, which lets the screen repaint between
        -- pages -- without it a first sync of a large library looks like a hang.
        if not Trapper:info(T(_("Kobo Sync: %1 items, page %2…\n\nTap to stop."), seen, page)) then
            -- Ask rather than stop outright: on an e-ink screen a stray tap
            -- should not throw away a walk that takes minutes.
            if Trapper:confirm(
                    _("Stop syncing?\n\nWhat has been synced so far is kept, and syncing again resumes from here."),
                    _("Continue"), _("Stop")) then
                cancelled = true
                return false
            end
        end
    end)
    -- Keep progress from already processed pages even on a failed run.
    state:set_synctoken(token or partial_token or state:get_synctoken())
    state:save()
    if not token then
        Trapper:clear()
        -- A failed page keeps the token for the pages before it, so say so:
        -- "failed" alone reads as if the whole run was thrown away.
        local message
        if state:get_synctoken() then
            message = T(_("Kobo Sync interrupted: %1\nNew: %2  Changed: %3\n\nSyncing again resumes from here."),
                err or _("unknown error"), result.new, result.changed)
        else
            message = T(_("Kobo Sync failed: %1"), err or _("unknown error"))
        end
        UIManager:show(InfoMessage:new{ text = message })
        return
    end
    if cancelled then
        -- The token covers the pages that were consumed, so the next run picks
        -- up where this one stopped rather than starting over.
        Trapper:clear()
        UIManager:show(InfoMessage:new{
            text = T(_("Kobo Sync stopped.\nNew: %1  Changed: %2\n\nThe next sync resumes from here."),
                result.new, result.changed),
        })
        return
    end

    Trapper:info(_("Kobo Sync: syncing reading progress…"))
    local pushed, pulled = self:applyReadingStates(state, api)
    state:save()
    Trapper:clear()

    -- Books deleted on the device outside the plugin would otherwise stay
    -- flagged as downloaded, and the planner would never fetch them again.
    local missing = SyncEngine.reconcile_downloads(state, function(path)
        return lfs.attributes(path, "mode") == "file"
    end)
    if missing > 0 then
        state:save()
    end

    local plan = SyncEngine.plan_downloads(state, self.download_mode)
    self:maybeConfirmDownloads(plan, first_sync, function(confirmed)
        local downloaded, failed = 0, 0
        if confirmed then
            downloaded, failed = self:downloadPlanned(state, api, plan)
            state:save()
        end
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
            if missing > 0 then
                table.insert(lines, T(_("Missing locally: %1"), missing))
            end
            if pushed > 0 or pulled > 0 then
                table.insert(lines, T(_("Reading progress: %1 sent, %2 received"), pushed, pulled))
            end
            UIManager:show(InfoMessage:new{ text = table.concat(lines, "\n") })
        end)
    end)
end

-- Bulk downloads are opt-in: ask on the first sync and for mass changes.
-- calls_back(confirmed) with the user's choice.
function KoboSync:maybeConfirmDownloads(plan, first_sync, callback)
    if #plan == 0 then
        callback(false)
        return
    end
    if not first_sync and #plan <= BULK_CONFIRM_THRESHOLD then
        callback(true)
        return
    end
    UIManager:show(ConfirmBox:new{
        text = T(_("Kobo Sync: download %1 book(s) to this device now?"), #plan),
        ok_text = _("Download"),
        -- Re-wrap: the dialog callback runs outside the sync coroutine.
        ok_callback = function()
            Trapper:wrap(function() callback(true) end)
        end,
        cancel_text = _("Not now"),
        cancel_callback = function() callback(false) end,
    })
end

function KoboSync:downloadPlanned(state, api, plan)
    if #plan == 0 then return 0, 0 end
    if lfs.attributes(self.download_dir, "mode") ~= "directory" then
        lfs.mkdir(self.download_dir)
    end
    local downloaded, failed = 0, 0
    for i, item in ipairs(plan) do
        local go_on = Trapper:info(T(_("Kobo Sync: downloading %1 of %2\n%3\n\nTap to cancel."),
            i, #plan, item.title or ""))
        if not go_on then break end
        local ok, dl_err = self:downloadBook(state, api, item)
        if ok then
            downloaded = downloaded + 1
        else
            failed = failed + 1
            logger.warn("KoboSync: download failed:", item.uuid, dl_err)
        end
    end
    Trapper:clear()
    return downloaded, failed
end

-- calibre-web ignores the size in the cover URL and returns its stored
-- thumbnail regardless; the values are what Kobo's own clients ask for.
local COVER_WIDTH, COVER_HEIGHT = 300, 450

function KoboSync:getCoverDir()
    if lfs.attributes(self.cover_dir, "mode") ~= "directory" then
        lfs.mkdir(DataStorage:getDataDir() .. "/cache")
        lfs.mkdir(self.cover_dir)
    end
    return self.cover_dir
end

-- The cover if it is already on disk. Never fetches: the browser calls this
-- once per visible row while drawing a page.
function KoboSync:cachedCoverPath(book)
    if not book or not book.cover_id then return nil end
    local path = self.cover_dir .. "/" .. book.cover_id .. ".jpg"
    if lfs.attributes(path, "mode") == "file" then
        return path
    end
    return nil
end

function KoboSync:setCoverMode(mode)
    self.cover_mode = mode
    self.settings:saveSetting("cover_mode", mode)
    self.settings:flush()
end

function KoboSync:setGridCols(cols)
    self.grid_cols = math.max(1, cols)
    self.settings:saveSetting("grid_cols", self.grid_cols)
    self.settings:flush()
end

-- The template is asked for once and remembered: it is a property of the
-- server, not of a book.
function KoboSync:getCoverTemplate(api)
    if self.image_url_template then
        return self.image_url_template
    end
    local init = api:get_initialization()
    local template = SyncEngine.image_url_template(init)
        or SyncEngine.default_image_url_template(self.server_url)
    if template then
        self.image_url_template = template
        self.settings:saveSetting("image_url_template", template)
        self.settings:flush()
    end
    return template
end

-- Returns the path to a locally cached cover, fetching it if needed.
function KoboSync:fetchCover(api, book)
    if not book.cover_id then
        return nil, _("this book was synced before covers were supported")
    end
    local path = self:getCoverDir() .. "/" .. book.cover_id .. ".jpg"
    if lfs.attributes(path, "mode") == "file" then
        return path
    end
    local template = self:getCoverTemplate(api)
    local url = SyncEngine.cover_url(template, book.cover_id, COVER_WIDTH, COVER_HEIGHT)
    if not url then
        return nil, _("no cover URL for this server")
    end
    local tmp_path = path .. ".part"
    local file = io.open(tmp_path, "wb")
    if not file then
        return nil, _("cannot write to the cover cache")
    end
    local ok, err = api:download(url, ltn12.sink.file(file))
    if not ok then
        os.remove(tmp_path)
        return nil, err
    end
    os.rename(tmp_path, path)
    return path
end

function KoboSync:downloadBook(state, api, item)
    local book = state:get_book(item.uuid)
    if not book then return nil, "not in catalog" end
    local base = SyncEngine.sanitize_filename(
        SyncEngine.collapse_series_title(book.title, book.series_name), book.author)
    local ext = SyncEngine.extension_for(item.format)
    local filename = SyncEngine.unique_filename(base, ext, item.uuid, function(name)
        -- Taken only when a different catalog book owns that file; an
        -- unowned leftover (e.g. after "Reset sync") is safely overwritten.
        local path = self.download_dir .. "/" .. name
        if not lfs.attributes(path, "mode") then return false end
        for _idx, other in ipairs(state:list_books()) do
            if other.local_path == path then
                return other.uuid ~= item.uuid
            end
        end
        return false
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
    -- Seed KOReader's sidecar with the server's reading state, if any.
    if book.server_state then
        self:applyServerState(path, book.server_state)
        state:upsert_book(item.uuid, { applied_state_time = book.server_state.LastModified })
    end
    return true
end

-- Reads the KOReader sidecar for a closed book; nil when never opened.
function KoboSync:readLocalState(path)
    local sidecar = DocSettings:findSidecarFile(path)
    if not sidecar then return nil end
    local doc_settings = DocSettings:open(path)
    local summary = doc_settings:readSetting("summary") or {}
    return {
        percent = doc_settings:readSetting("percent_finished") or 0,
        status = summary.status,
        modified_time = lfs.attributes(sidecar, "modification"),
    }
end

-- Writes server progress into a closed book's sidecar. The reading position
-- itself cannot be restored from a percentage; ReaderReady offers the jump.
function KoboSync:applyServerState(path, server_state)
    local st = ReadingState.from_kobo(server_state)
    if not st then return end
    local doc_settings = DocSettings:open(path)
    doc_settings:saveSetting("percent_finished", st.percent)
    if st.status then
        local summary = doc_settings:readSetting("summary") or {}
        summary.status = st.status
        summary.modified = os.date("%Y-%m-%d", st.modified_time or os.time())
        doc_settings:saveSetting("summary", summary)
    end
    doc_settings:flush()
end

function KoboSync:uuidForPath(state, path)
    for _idx, book in ipairs(state:list_books()) do
        if book.local_path == path then return book.uuid end
    end
    return nil
end

-- Uploads every queued reading state; failures stay queued for next time.
function KoboSync:flushPendingStates(state, api)
    local pushed = 0
    for uuid, payload in pairs(state:pending_states()) do
        -- Skip the push when the server moved past our queued snapshot.
        local book = state:get_book(uuid)
        local server_state = book and book.server_state
        local queued_time = ReadingState.iso_to_epoch(payload.LastModified)
        if server_state and ReadingState.resolve(
                { modified_time = queued_time }, server_state) == "pull" then
            state:clear_pending_state(uuid)
        else
            local ok = api:put_state(uuid, payload)
            if ok then
                state:clear_pending_state(uuid)
                state:upsert_book(uuid, {
                    server_state = payload,
                    applied_state_time = payload.LastModified,
                })
                pushed = pushed + 1
            end
        end
    end
    return pushed
end

-- Two-way reading state sync: push the queue, then pull server-newer states
-- into local sidecars (skipping the currently open document).
function KoboSync:applyReadingStates(state, api)
    local pushed = self:flushPendingStates(state, api)
    local pulled = 0
    local open_file = self.ui and self.ui.document and self.ui.document.file
    for _idx, book in ipairs(state:list_books()) do
        if book.downloaded and book.local_path and book.server_state
                and book.local_path ~= open_file
                and book.server_state.LastModified ~= book.applied_state_time then
            local local_state = self:readLocalState(book.local_path)
            if ReadingState.resolve(local_state, book.server_state) == "pull" then
                self:applyServerState(book.local_path, book.server_state)
                pulled = pulled + 1
            end
            state:upsert_book(book.uuid, {
                applied_state_time = book.server_state.LastModified,
            })
        end
    end
    return pushed, pulled
end

-- Queue (and best-effort upload) the reading state whenever a book from the
-- catalog is closed.
function KoboSync:onCloseDocument()
    if not self.upload_on_close or not self.server_url then return end
    local file = self.ui.document and self.ui.document.file
    if not file then return end
    local state = self:getState()
    local uuid = self:uuidForPath(state, file)
    if not uuid then return end
    local summary = self.ui.doc_settings:readSetting("summary") or {}
    local payload = ReadingState.to_kobo(uuid, {
        percent = self.ui.doc_settings:readSetting("percent_finished") or 0,
        status = summary.status,
        modified_time = os.time(),
    }, (state:get_book(uuid) or {}).server_state)
    state:set_pending_state(uuid, payload)
    if NetworkMgr:isOnline() then
        self:flushPendingStates(state, self:getApi())
    end
    state:save()
end

-- When opening a book whose server progress is ahead, offer to jump there.
function KoboSync:onReaderReady()
    if not self.server_url then return end
    local file = self.ui.document and self.ui.document.file
    if not file then return end
    local state = self:getState()
    local uuid = self:uuidForPath(state, file)
    local book = uuid and state:get_book(uuid)
    if not book or not book.server_state then return end
    local local_state = self:readLocalState(file)
    if ReadingState.resolve(local_state, book.server_state) ~= "pull" then return end
    local st = ReadingState.from_kobo(book.server_state)
    if not st or (st.percent or 0) <= 0 then return end
    local percent = math.floor(st.percent * 1000 + 0.5) / 10
    UIManager:show(ConfirmBox:new{
        text = T(_("Kobo Sync: the server has newer reading progress (%1%). Jump there?"), percent),
        ok_text = _("Jump"),
        ok_callback = function()
            self.ui:handleEvent(Event:new("GotoPercent", percent))
            state:upsert_book(uuid, { applied_state_time = book.server_state.LastModified })
            state:save()
        end,
        cancel_text = _("Stay"),
    })
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
