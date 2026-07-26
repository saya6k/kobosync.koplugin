local ConfirmBox = require("ui/widget/confirmbox")
local DataStorage = require("datastorage")
local Dispatcher = require("dispatcher")
local DocSettings = require("docsettings")
local DownloadMgr = require("ui/downloadmgr")
local InfoMessage = require("ui/widget/infomessage")
local InputDialog = require("ui/widget/inputdialog")
local LuaSettings = require("luasettings")
local NetworkMgr = require("ui/network/manager")
local Notification = require("ui/widget/notification")
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
local _ = require("kobosync_gettext")
local ffiUtil = require("ffi/util")
local T = ffiUtil.template

local Event = require("ui/event")

local KoboApi = require("kobosync_koboapi")
local ReadingState = require("kobosync_readingstate")
local StateStore = require("kobosync_statestore")
local SyncEngine = require("kobosync_syncengine")
local SyncIndicator = require("kobosync_syncindicator")
local Wire = require("kobosync_wire")

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
    -- Minutes between unattended syncs; 0 is off.
    self.sync_interval = tonumber(self.settings:readSetting("sync_interval")) or 0
    self.image_url_template = self.settings:readSetting("image_url_template")
    -- "off" | "grid". A cover boxed by a list row stayed too small to be worth
    -- the fetch, so the list variant was dropped; anyone left on it, or on the
    -- boolean that preceded it, lands on the grid.
    local cover_mode = self.settings:readSetting("cover_mode")
    if cover_mode == "list" or (cover_mode == nil and self.settings:isTrue("show_covers")) then
        cover_mode = "grid"
    end
    self.cover_mode = cover_mode or "off"
    self.grid_cols = tonumber(self.settings:readSetting("grid_cols")) or 3
    self.cover_dir = DataStorage:getDataDir() .. "/cache/kobosync"
    self:onDispatcherRegisterActions()
    self.ui.menu:registerToMainMenu(self)
    self:rescheduleSync()
end

-- Minutes offered for unattended syncs; 0 turns them off.
local SYNC_INTERVALS = { 0, 15, 30, 60 }

function KoboSync:rescheduleSync()
    if self.scheduled_sync then
        UIManager:unschedule(self.scheduled_sync)
        self.scheduled_sync = nil
    end
    if not self.server_url or self.sync_interval <= 0 then
        return
    end
    self.scheduled_sync = function() self:runScheduledSync() end
    UIManager:scheduleIn(self.sync_interval * 60, self.scheduled_sync)
end

function KoboSync:runScheduledSync()
    -- Re-arm first: a run that is skipped, or one that fails, must not end the
    -- schedule.
    self:rescheduleSync()
    if self.syncing or not self.server_url then
        return
    end
    -- Never bring the network up. Newer Android forbids an app turning Wi-Fi on
    -- at all, and doing it unasked is not what an unattended sync should mean.
    if not NetworkMgr:isOnline() then
        return
    end
    Trapper:wrap(function()
        self.syncing = true
        local ok, err = pcall(function() self:doSync{ scheduled = true } end)
        self.syncing = false
        self:hideSyncIndicator()
        if not ok then
            logger.warn("KoboSync: scheduled sync failed:", err)
        end
    end)
end

function KoboSync:syncIntervalMenu()
    local items = {}
    for _idx, minutes in ipairs(SYNC_INTERVALS) do
        table.insert(items, {
            text = minutes == 0 and _("Off") or T(_("Every %1 minutes"), minutes),
            checked_func = function() return self.sync_interval == minutes end,
            radio = true,
            callback = function()
                self.sync_interval = minutes
                self:saveSettings()
                self:rescheduleSync()
            end,
        })
    end
    return items
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
    self.settings:saveSetting("sync_interval", self.sync_interval)
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

-- Library pages block for about ten seconds each while the server builds them.
-- Run in process, that is long enough for Android to decide the app has hung
-- and offer to close it. Trapper has a fork-and-poll runner for exactly this,
-- but it puts a TrapWidget over the screen that claims every tap -- fine for a
-- two-second lookup, and unbearable for the minutes a full walk takes, since
-- the reader underneath stops responding.
--
-- So: the same loop without that widget. The coroutine yields to UIManager
-- between checks, so the event loop keeps running and taps reach whatever is on
-- screen; the walk is stopped from the menu instead of by tapping.
local SUBPROCESS_POLL_SECONDS = 0.25

-- Reap the child so it does not linger as a zombie. It may need a moment after
-- being terminated, hence the retry.
local function collect_subprocess(pid)
    local function collect()
        if not ffiUtil.isSubProcessDone(pid) then
            UIManager:scheduleIn(5, collect)
        end
    end
    UIManager:scheduleIn(1, collect)
end

-- Runs `task` in a subprocess and returns what it wrote, as a string.
function KoboSync:runInSubprocessNonModal(task)
    local co = coroutine.running()
    if not co then
        -- Nothing to keep responsive; run it here.
        return task()
    end
    local pid, parent_read_fd = ffiUtil.runInSubProcess(function(_pid, child_write_fd)
        ffiUtil.writeToFD(child_write_fd, task() or "", true)
    end, true)
    if not pid then
        return nil, "could not start a subprocess"
    end
    while true do
        local resume = function() coroutine.resume(co, true) end
        UIManager:scheduleIn(SUBPROCESS_POLL_SECONDS, resume)
        coroutine.yield()
        if self.sync_cancelled then
            UIManager:unschedule(resume)
            ffiUtil.terminateSubProcess(pid)
            ffiUtil.readAllFromFD(parent_read_fd) -- also closes it
            collect_subprocess(pid)
            return nil, KoboApi.CANCELLED
        end
        local done = ffiUtil.isSubProcessDone(pid)
        -- A child blocked writing more than the pipe buffer holds is not done
        -- yet but already has data waiting, so both have to be checked.
        local readable = ffiUtil.getNonBlockingReadSize(parent_read_fd) ~= 0
        if done or readable then
            local output = readable and ffiUtil.readAllFromFD(parent_read_fd) or ""
            if not done then
                collect_subprocess(pid)
            end
            return output
        end
    end
end

-- A message in the corner for as long as the walk runs. A toast would say the
-- same thing but vanish after a couple of seconds, leaving no sign that
-- anything is still going on.
function KoboSync:showSyncIndicator(text)
    self:hideSyncIndicator()
    self.sync_indicator = SyncIndicator:new{ text = text }
    UIManager:show(self.sync_indicator)
end

function KoboSync:hideSyncIndicator()
    if self.sync_indicator then
        UIManager:close(self.sync_indicator)
        self.sync_indicator = nil
    end
end

function KoboSync:syncRequest(req)
    local output, err = self:runInSubprocessNonModal(function()
        return Wire.encode(http_request(req))
    end)
    if not output then
        return nil, err
    end
    return Wire.decode(output)
end

function KoboSync:getApi()
    return KoboApi.new{
        base_url = self.server_url,
        request = http_request,
        sync_request = function(req) return self:syncRequest(req) end,
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
                enabled_func = function()
                    return self.server_url ~= nil and not self.syncing
                end,
                callback = function() self:onKoboSyncSync() end,
            },
            {
                -- The walk runs in the background with nothing covering the
                -- screen, so this is where it gets stopped.
                text = _("Stop synchronizing"),
                enabled_func = function() return self.syncing == true end,
                callback = function()
                    self.sync_cancelled = true
                    UIManager:show(InfoMessage:new{
                        text = _("Kobo Sync: stopping after the current page.\n\n"
                            .. "What has been synced is kept, and syncing again resumes from here."),
                    })
                end,
            },
            {
                text = _("Browse server library"),
                enabled_func = function() return self.server_url ~= nil end,
                callback = function()
                    local Browser = require("kobosync_browser")
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
                -- Named for the state it keeps rather than the action it
                -- takes: it fetches every book the catalog lists and the device
                -- lacks, which on a first sync is the entire library, not just
                -- what arrived since last time.
                text = _("Keep every book on this device"),
                help_text = _("Downloads every book in the library and fetches new ones as "
                    .. "they arrive; on a first sync that means the whole library. "
                    .. "When disabled, syncing only updates the catalog and books are "
                    .. "downloaded one at a time from the server library browser."),
                checked_func = function() return self.download_mode == "auto" end,
                callback = function()
                    self.download_mode = self.download_mode == "auto" and "on_demand" or "auto"
                    self:saveSettings()
                end,
            },
            {
                text_func = function()
                    if self.sync_interval > 0 then
                        return T(_("Sync automatically: every %1 minutes"), self.sync_interval)
                    end
                    return _("Sync automatically: off")
                end,
                help_text = _("Runs only while Wi-Fi is already on, and only refreshes the "
                    .. "catalog: an unattended run never starts downloads, and deletions it "
                    .. "finds are held until the next sync you start yourself."),
                sub_item_table_func = function() return self:syncIntervalMenu() end,
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
    if self.syncing then
        UIManager:show(InfoMessage:new{ text = _("Kobo Sync: already synchronizing.") })
        return true
    end
    NetworkMgr:runWhenOnline(function()
        Trapper:wrap(function()
            self.syncing = true
            local ok, err = pcall(function() self:doSync() end)
            self.syncing = false
            self:hideSyncIndicator()
            if not ok then
                logger.warn("KoboSync: sync failed:", err)
                UIManager:show(InfoMessage:new{
                    text = T(_("Kobo Sync failed: %1"), tostring(err)),
                })
            end
        end)
    end)
    return true
end

function KoboSync:doSync(opts)
    opts = opts or {}
    local state = self:getState()
    local api = self:getApi()
    local first_sync = state:get_synctoken() == nil
    local result = SyncEngine.new_result()
    local seen = 0
    self.sync_cancelled = false
    -- The protocol sends no total, so progress counts up rather than filling a
    -- bar: a response advertises a sync token and whether more pages follow,
    -- nothing more.
    self:showSyncIndicator(_("Kobo Sync: synchronizing…"))
    local token, err, partial_token = api:sync(state:get_synctoken(), function(items, page)
        SyncEngine.process_items(state, items, result)
        seen = seen + #items
        self:showSyncIndicator(T(_("Kobo Sync: %1 items, page %2…"), seen, page))
        if self.sync_cancelled then
            return false
        end
    end)
    local cancelled = self.sync_cancelled
    -- Keep progress from already processed pages even on a failed run.
    state:set_synctoken(token or partial_token or state:get_synctoken())
    state:save()
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

    -- A scheduled run only refreshes the catalog: it must not put a download
    -- confirmation, or a deletion one, in front of someone who is reading.
    if opts.scheduled then
        state:queue_deletions(result.delete_candidates)
        state:save()
        self:reportSync(result, 0, 0, pushed, pulled, missing, true)
        return
    end

    local plan = SyncEngine.plan_downloads(state, self.download_mode)
    self:maybeConfirmDownloads(plan, first_sync, function(confirmed)
        local downloaded, failed = 0, 0
        if confirmed then
            downloaded, failed = self:downloadPlanned(state, api, plan)
            state:save()
        end
        -- Anything a scheduled run could not ask about is answered here.
        local candidates = state:pending_deletions()
        for _idx, candidate in ipairs(result.delete_candidates) do
            table.insert(candidates, candidate)
        end
        self:confirmDeletions(state, candidates, function()
            state:clear_pending_deletions()
            state:save()
            self:reportSync(result, downloaded, failed, pushed, pulled, missing, false)
        end)
    end)
end

-- A scheduled run reports through a toast: it neither covers the page being
-- read nor waits to be dismissed.
function KoboSync:reportSync(result, downloaded, failed, pushed, pulled, missing, quiet)
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
    local text = table.concat(lines, "\n")
    if quiet then
        UIManager:show(Notification:new{ text = text:gsub("\n", "  ") })
    else
        UIManager:show(InfoMessage:new{ text = text })
    end
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
    local pulled = 0
    local open_file = self.ui and self.ui.document and self.ui.document.file
    for _idx, book in ipairs(state:list_books()) do
        -- The open document is left alone: its sidecar is written on close,
        -- and reading it mid-session would send a half-finished position.
        if book.downloaded and book.local_path and book.local_path ~= open_file then
            local local_state = self:readLocalState(book.local_path)
            local action = ReadingState.plan(local_state, book.server_state, book)
            if action == "pull" then
                self:applyServerState(book.local_path, book.server_state)
                pulled = pulled + 1
                -- Record the sidecar we just wrote, so it is not offered back
                -- to the server as a local change on the next run.
                local written = self:readLocalState(book.local_path)
                state:upsert_book(book.uuid, {
                    applied_state_time = book.server_state.LastModified,
                    pushed_local_time = written and written.modified_time,
                })
            elseif action == "push" then
                state:set_pending_state(book.uuid,
                    ReadingState.to_kobo(book.uuid, local_state, book.server_state))
                state:upsert_book(book.uuid, {
                    pushed_local_time = local_state.modified_time,
                })
            end
        end
    end
    -- Flushed after the walk so states found just now go out in this same run.
    return self:flushPendingStates(state, api), pulled
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
