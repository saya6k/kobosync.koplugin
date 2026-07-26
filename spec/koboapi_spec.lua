local json = require("dkjson")
local KoboApi = dofile("koboapi.lua")

-- Builds a fake request function serving scripted responses in order,
-- recording every request it receives.
local function fake_http(responses)
    local calls = {}
    local i = 0
    local fn = function(req)
        table.insert(calls, req)
        i = i + 1
        local r = responses[math.min(i, #responses)]
        if type(r) == "function" then return r(req) end
        return r
    end
    return fn, calls
end

local function api_with(responses)
    local request, calls = fake_http(responses)
    local api = KoboApi.new{
        base_url = "https://example.com/kobo/token123/",
        request = request,
        json = json,
    }
    return api, calls
end

describe("KoboApi.sync", function()
    it("sends no synctoken header on first sync and stores the returned one", function()
        local api, calls = api_with({
            { code = 200, headers = { ["x-kobo-synctoken"] = "tok-1" }, body = "[]" },
        })
        local pages = {}
        local token = api:sync(nil, function(items) table.insert(pages, items) end)
        assert.are.equal("tok-1", token)
        assert.are.equal(1, #calls)
        assert.is_nil(calls[1].headers["x-kobo-synctoken"])
        assert.are.equal("https://example.com/kobo/token123/v1/library/sync", calls[1].url)
        assert.are.equal(1, #pages)
    end)

    it("attaches a stored synctoken", function()
        local api, calls = api_with({
            { code = 200, headers = { ["x-kobo-synctoken"] = "tok-2" }, body = "[]" },
        })
        api:sync("tok-1", function() end)
        assert.are.equal("tok-1", calls[1].headers["x-kobo-synctoken"])
    end)

    it("follows x-kobo-sync: continue across pages, updating the token", function()
        local api, calls = api_with({
            { code = 200, headers = { ["x-kobo-synctoken"] = "t1", ["x-kobo-sync"] = "continue" },
              body = '[{"NewEntitlement":{}}]' },
            { code = 200, headers = { ["x-kobo-synctoken"] = "t2", ["x-kobo-sync"] = "continue" },
              body = '[{"NewEntitlement":{}}]' },
            { code = 200, headers = { ["x-kobo-synctoken"] = "t3" }, body = "[]" },
        })
        local pages = {}
        local token = api:sync(nil, function(items) table.insert(pages, items) end)
        assert.are.equal("t3", token)
        assert.are.equal(3, #calls)
        assert.are.equal(3, #pages)
        assert.are.equal("t1", calls[2].headers["x-kobo-synctoken"])
        assert.are.equal("t2", calls[3].headers["x-kobo-synctoken"])
    end)

    it("reads response headers case-insensitively", function()
        local api = select(1, api_with({
            { code = 200, headers = { ["X-Kobo-SyncToken"] = "TOK" }, body = "[]" },
        }))
        local token = api:sync(nil, function() end)
        assert.are.equal("TOK", token)
    end)

    it("returns the error and last good token on HTTP error mid-pagination", function()
        local api = select(1, api_with({
            { code = 200, headers = { ["x-kobo-synctoken"] = "t1", ["x-kobo-sync"] = "continue" },
              body = "[]" },
            { code = 500, headers = {}, body = "boom" },
        }))
        local token, err, partial = api:sync(nil, function() end)
        assert.is_nil(token)
        assert.are.equal("HTTP 500", err)
        assert.are.equal("t1", partial)
    end)

    it("returns an error on network failure", function()
        local api = select(1, api_with({
            function() return nil, "connection refused" end,
        }))
        local token, err = api:sync(nil, function() end)
        assert.is_nil(token)
        assert.are.equal("connection refused", err)
    end)

    it("returns an error on malformed JSON", function()
        local api = select(1, api_with({
            { code = 200, headers = {}, body = "not json{" },
        }))
        local token, err = api:sync(nil, function() end)
        assert.is_nil(token)
        assert.are.equal("invalid JSON in sync response", err)
    end)
end)

describe("KoboApi reading state", function()
    it("gets state for a book", function()
        local api, calls = api_with({
            { code = 200, headers = {}, body = '[{"EntitlementId":"uuid-1"}]' },
        })
        local state = api:get_state("uuid-1")
        assert.are.equal("GET", calls[1].method)
        assert.are.equal("https://example.com/kobo/token123/v1/library/uuid-1/state", calls[1].url)
        assert.are.equal("uuid-1", state[1].EntitlementId)
    end)

    it("puts state wrapped in ReadingStates with JSON content type", function()
        local api, calls = api_with({
            { code = 200, headers = {}, body = '{"RequestResult":"Success"}' },
        })
        local result = api:put_state("uuid-1", { EntitlementId = "uuid-1", StatusInfo = { Status = "Reading" } })
        assert.are.equal("PUT", calls[1].method)
        assert.are.equal("application/json", calls[1].headers["Content-Type"])
        local sent = json.decode(calls[1].body)
        assert.are.equal("uuid-1", sent.ReadingStates[1].EntitlementId)
        assert.are.equal("Reading", sent.ReadingStates[1].StatusInfo.Status)
        assert.are.equal("Success", result.RequestResult)
    end)

    it("propagates HTTP errors", function()
        local api = select(1, api_with({ { code = 401, headers = {}, body = "" } }))
        local state, err = api:get_state("uuid-1")
        assert.is_nil(state)
        assert.are.equal("HTTP 401", err)
    end)
end)

describe("KoboApi.download", function()
    it("passes the sink through and succeeds on 200", function()
        local api, calls = api_with({ { code = 200, headers = {}, body = "" } })
        local sink = function() end
        local ok = api:download("https://example.com/kobo/token123/download/1/kepub", sink)
        assert.is_true(ok)
        assert.are.equal(sink, calls[1].sink)
    end)

    it("fails on HTTP error", function()
        local api = select(1, api_with({ { code = 404, headers = {}, body = "" } }))
        local ok, err = api:download("https://example.com/x", function() end)
        assert.is_nil(ok)
        assert.are.equal("HTTP 404", err)
    end)
end)

describe("KoboApi.sync cancellation", function()
    it("passes the page number to on_page", function()
        local api = api_with({
            { code = 200, headers = { ["x-kobo-synctoken"] = "t1", ["x-kobo-sync"] = "continue" }, body = "[]" },
            { code = 200, headers = { ["x-kobo-synctoken"] = "t2" }, body = "[]" },
        })
        local pages = {}
        api:sync(nil, function(_items, page) table.insert(pages, page) end)
        assert.are.same({ 1, 2 }, pages)
    end)

    it("stops walking when on_page returns false, keeping the token so far", function()
        local api, calls = api_with({
            { code = 200, headers = { ["x-kobo-synctoken"] = "t1", ["x-kobo-sync"] = "continue" }, body = "[]" },
            { code = 200, headers = { ["x-kobo-synctoken"] = "t2", ["x-kobo-sync"] = "continue" }, body = "[]" },
        })
        local seen = 0
        local token = api:sync(nil, function()
            seen = seen + 1
            return false
        end)
        assert.are.equal(1, seen)
        assert.are.equal(1, #calls)
        -- The token of the consumed page, so the next run resumes here.
        assert.are.equal("t1", token)
    end)

    it("keeps going when on_page returns nil, as callers that ignore it do", function()
        local api, calls = api_with({
            { code = 200, headers = { ["x-kobo-synctoken"] = "t1", ["x-kobo-sync"] = "continue" }, body = "[]" },
            { code = 200, headers = { ["x-kobo-synctoken"] = "t2" }, body = "[]" },
        })
        local token = api:sync(nil, function() end)
        assert.are.equal(2, #calls)
        assert.are.equal("t2", token)
    end)
end)

describe("KoboApi.get_initialization", function()
    it("asks the resource endpoint and decodes it", function()
        local api, calls = api_with({
            { code = 200, headers = {}, body = '{"Resources":{"image_url_template":"https://s/{ImageId}"}}' },
        })
        local init = api:get_initialization()
        assert.are.equal("https://example.com/kobo/token123/v1/initialization", calls[1].url)
        assert.are.equal("GET", calls[1].method)
        assert.are.equal("https://s/{ImageId}", init.Resources.image_url_template)
    end)
end)

describe("KoboApi.sync retries", function()
    -- Retries are driven by an injected sleep so the suite never waits.
    local function api_with_retries(responses)
        local request, calls = fake_http(responses)
        local slept = {}
        local api = KoboApi.new{
            base_url = "https://example.com/kobo/token123/",
            request = request,
            json = json,
            retry_delays = { 1, 2 },
            sleep = function(seconds) table.insert(slept, seconds) end,
        }
        return api, calls, slept
    end

    it("retries a transport failure and succeeds", function()
        local api, calls, slept = api_with_retries({
            function() return nil, "Connection timed out" end,
            { code = 200, headers = { ["x-kobo-synctoken"] = "t1" }, body = "[]" },
        })
        local token = api:sync(nil, function() end)
        assert.are.equal("t1", token)
        assert.are.equal(2, #calls)
        assert.are.same({ 1 }, slept)
    end)

    it("gives up after the last delay and reports the transport error", function()
        local api, calls, slept = api_with_retries({
            function() return nil, "Connection timed out" end,
        })
        local token, err = api:sync(nil, function() end)
        assert.is_nil(token)
        assert.are.equal("Connection timed out", err)
        assert.are.equal(3, #calls) -- first try plus two retries
        assert.are.same({ 1, 2 }, slept)
    end)

    it("retries a server error but not a client error", function()
        local api, calls = api_with_retries({ { code = 503, headers = {}, body = "" } })
        local _, err = api:sync(nil, function() end)
        assert.are.equal("HTTP 503", err)
        assert.are.equal(3, #calls)

        local api2, calls2 = api_with_retries({ { code = 401, headers = {}, body = "" } })
        local _, err2 = api2:sync(nil, function() end)
        assert.are.equal("HTTP 401", err2)
        assert.are.equal(1, #calls2)
    end)

    it("keeps the token of the pages that did get through", function()
        local api = api_with_retries({
            { code = 200, headers = { ["x-kobo-synctoken"] = "t1", ["x-kobo-sync"] = "continue" }, body = "[]" },
            function() return nil, "Connection timed out" end,
        })
        local token, err, partial = api:sync(nil, function() end)
        assert.is_nil(token)
        assert.are.equal("Connection timed out", err)
        assert.are.equal("t1", partial)
    end)

    it("does not sleep when nothing fails", function()
        local api, calls, slept = api_with_retries({
            { code = 200, headers = { ["x-kobo-synctoken"] = "t1" }, body = "[]" },
        })
        api:sync(nil, function() end)
        assert.are.equal(1, #calls)
        assert.are.equal(0, #slept)
    end)
end)
