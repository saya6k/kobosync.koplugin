-- Persistent plugin state: opaque sync token, book catalog, and the queue of
-- reading states waiting to be uploaded. Pure logic: stores JSON at an
-- injected path, JSON implementation injected (rapidjson in KOReader).
--
-- Catalog entry (per book uuid): free-form table owned by the caller, e.g.
-- { title, author, download_urls, revision_id, local_path, downloaded,
--   server_state, server_location }

local StateStore = {}
StateStore.__index = StateStore

local function empty_data()
    return {
        version = 1,
        synctoken = nil,
        books = {},
        pending_states = {},
        pending_deletions = {},
    }
end

function StateStore.new(opts)
    assert(opts.path, "path required")
    assert(opts.json, "json module required")
    local self = setmetatable({}, StateStore)
    self.path = opts.path
    self.json = opts.json
    self.data = empty_data()
    self:_load()
    return self
end

function StateStore:_load()
    local f = io.open(self.path, "r")
    if not f then return end
    local content = f:read("*a")
    f:close()
    local ok, decoded = pcall(self.json.decode, content)
    -- A corrupt or foreign file must never crash the plugin: fall back to
    -- an empty store, which just causes a full re-sync.
    if ok and type(decoded) == "table" and type(decoded.books) == "table" then
        self.data = decoded
        self.data.pending_states = self.data.pending_states or {}
        self.data.pending_deletions = self.data.pending_deletions or {}
    end
end

function StateStore:save()
    local content = self.json.encode(self.data)
    local tmp = self.path .. ".tmp"
    local f, err = io.open(tmp, "w")
    if not f then return nil, err end
    f:write(content)
    f:close()
    return os.rename(tmp, self.path)
end

function StateStore:get_synctoken()
    return self.data.synctoken
end

function StateStore:set_synctoken(token)
    self.data.synctoken = token
end

function StateStore:get_book(uuid)
    return self.data.books[uuid]
end

-- Merges fields into the existing entry (creating it if needed), so callers
-- can update server metadata without wiping local fields like local_path.
function StateStore:upsert_book(uuid, fields)
    local entry = self.data.books[uuid] or {}
    for k, v in pairs(fields) do
        entry[k] = v
    end
    self.data.books[uuid] = entry
    return entry
end

function StateStore:remove_book(uuid)
    self.data.books[uuid] = nil
    self.data.pending_states[uuid] = nil
end

-- Returns { { uuid = ..., <entry fields> }, ... }; order is unspecified.
function StateStore:list_books()
    local books = {}
    for uuid, entry in pairs(self.data.books) do
        local item = { uuid = uuid }
        for k, v in pairs(entry) do item[k] = v end
        table.insert(books, item)
    end
    return books
end

function StateStore:set_pending_state(uuid, state)
    self.data.pending_states[uuid] = state
end

function StateStore:clear_pending_state(uuid)
    self.data.pending_states[uuid] = nil
end

function StateStore:pending_states()
    return self.data.pending_states
end

-- Full reset ("Reset sync" menu): next sync starts from scratch.
-- Deletions nobody has answered yet. A scheduled sync must not put a dialog on
-- screen, but the server reports a removal only once, so candidates are held
-- here until an interactive sync can ask about them. Queued by uuid, so a book
-- queued twice is still asked about once.
function StateStore:queue_deletions(candidates)
    local queued = {}
    for _idx, entry in ipairs(self.data.pending_deletions) do
        queued[entry.uuid] = true
    end
    for _idx, candidate in ipairs(candidates or {}) do
        if candidate.uuid and not queued[candidate.uuid] then
            queued[candidate.uuid] = true
            table.insert(self.data.pending_deletions, {
                uuid = candidate.uuid,
                title = candidate.title,
                local_path = candidate.local_path,
            })
        end
    end
end

function StateStore:pending_deletions()
    return self.data.pending_deletions
end

function StateStore:clear_pending_deletions()
    self.data.pending_deletions = {}
end

function StateStore:reset()
    self.data = empty_data()
end

return StateStore
