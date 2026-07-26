-- Kobo Sync protocol client. Pure logic: no KOReader dependencies.
-- HTTP and JSON implementations are injected so the module is unit-testable.
--
-- opts.request(req) -> { code = number, headers = table, body = string } | nil, err
--   req = { url = string, method = string, headers = table, body = string?, sink = function? }
-- opts.json -> module with encode(value) / decode(string)
-- opts.base_url -> "https://host/kobo/<auth_token>" (no trailing slash)

local KoboApi = {}
KoboApi.__index = KoboApi

local SYNC_TOKEN_HEADER = "x-kobo-synctoken"
local SYNC_CONTINUE_HEADER = "x-kobo-sync"
local MAX_SYNC_PAGES = 1000

function KoboApi.new(opts)
    assert(opts.base_url, "base_url required")
    assert(opts.request, "request function required")
    assert(opts.json, "json module required")
    local self = setmetatable({}, KoboApi)
    self.base_url = opts.base_url:gsub("/+$", "")
    self.request = opts.request
    self.json = opts.json
    return self
end

-- Response header lookup, case-insensitive (luasocket lowercases, others may not).
local function get_header(headers, name)
    if not headers then return nil end
    for k, v in pairs(headers) do
        if k:lower() == name then return v end
    end
    return nil
end

function KoboApi:_request_json(method, path, body)
    local req = {
        url = self.base_url .. path,
        method = method,
        headers = { ["Accept"] = "application/json" },
    }
    if body ~= nil then
        req.body = self.json.encode(body)
        req.headers["Content-Type"] = "application/json"
    end
    local resp, err = self.request(req)
    if not resp then
        return nil, err or "network error"
    end
    if resp.code ~= 200 then
        return nil, "HTTP " .. tostring(resp.code)
    end
    local ok, decoded = pcall(self.json.decode, resp.body)
    if not ok or decoded == nil then
        return nil, "invalid JSON in response"
    end
    return decoded, nil, resp
end

-- Incremental library sync. Calls on_page(items, page_number) for every page
-- received; returning false from it stops the walk and returns the token for
-- the pages consumed so far, so a cancelled sync resumes rather than restarts.
-- The sync token is treated as an opaque string: sent as-is, stored as-is.
-- Returns the newest sync token, or nil, err (the token from already
-- processed pages is returned as the third value so progress is not lost).
function KoboApi:sync(synctoken, on_page)
    local token = synctoken
    for page = 1, MAX_SYNC_PAGES do
        local req = {
            url = self.base_url .. "/v1/library/sync",
            method = "GET",
            headers = { ["Accept"] = "application/json" },
        }
        if token then
            req.headers[SYNC_TOKEN_HEADER] = token
        end
        local resp, err = self.request(req)
        if not resp then
            return nil, err or "network error", token
        end
        if resp.code ~= 200 then
            return nil, "HTTP " .. tostring(resp.code), token
        end
        local ok, items = pcall(self.json.decode, resp.body)
        if not ok or type(items) ~= "table" then
            return nil, "invalid JSON in sync response", token
        end
        local go_on = on_page(items, page)
        token = get_header(resp.headers, SYNC_TOKEN_HEADER) or token
        if go_on == false then
            return token
        end
        if get_header(resp.headers, SYNC_CONTINUE_HEADER) ~= "continue" then
            return token
        end
    end
    return nil, "sync did not terminate after " .. MAX_SYNC_PAGES .. " pages", token
end

-- Resource endpoint; carries the cover image URL template among other hosts.
function KoboApi:get_initialization()
    return self:_request_json("GET", "/v1/initialization")
end

function KoboApi:get_state(book_uuid)
    return self:_request_json("GET", "/v1/library/" .. book_uuid .. "/state")
end

-- reading_state is a complete ReadingState object (with EntitlementId).
function KoboApi:put_state(book_uuid, reading_state)
    return self:_request_json("PUT", "/v1/library/" .. book_uuid .. "/state",
        { ReadingStates = { reading_state } })
end

-- Streams a book file to sink(chunk). url comes from BookMetadata.DownloadUrls
-- and is absolute. Returns true, or nil, err.
function KoboApi:download(url, sink)
    local resp, err = self.request({
        url = url,
        method = "GET",
        headers = {},
        sink = sink,
    })
    if not resp then
        return nil, err or "network error"
    end
    if resp.code ~= 200 then
        return nil, "HTTP " .. tostring(resp.code)
    end
    return true
end

return KoboApi
