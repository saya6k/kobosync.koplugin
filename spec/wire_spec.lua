local Wire = dofile("kobosync_wire.lua")

describe("Wire", function()
    it("round-trips a response", function()
        local resp = Wire.decode(Wire.encode({
            code = 200,
            headers = { ["x-kobo-synctoken"] = "tok", ["x-kobo-sync"] = "continue" },
            body = '[{"a":1}]',
        }))
        assert.are.equal(200, resp.code)
        assert.are.equal("tok", resp.headers["x-kobo-synctoken"])
        assert.are.equal("continue", resp.headers["x-kobo-sync"])
        assert.are.equal('[{"a":1}]', resp.body)
    end)

    it("keeps a body that contains blank lines", function()
        -- The split is on the first blank line, which headers cannot contain
        -- but a body can.
        local body = "[1]\n\n[2]\n\n[3]"
        assert.are.equal(body, Wire.decode(Wire.encode({ code = 200, body = body })).body)
    end)

    it("lowercases header names, as luasocket does", function()
        local resp = Wire.decode(Wire.encode({
            code = 200, headers = { ["X-Kobo-SyncToken"] = "tok" }, body = "",
        }))
        assert.are.equal("tok", resp.headers["x-kobo-synctoken"])
    end)

    it("carries a failed request across as an error", function()
        local resp, err = Wire.decode(Wire.encode(nil, "Connection timed out"))
        assert.is_nil(resp)
        assert.are.equal("Connection timed out", err)
    end)

    it("names a missing error rather than losing it", function()
        local err = select(2, Wire.decode(Wire.encode(nil, nil)))
        assert.are.equal("network error", err)
    end)

    it("handles an empty body and no headers", function()
        local resp = Wire.decode(Wire.encode({ code = 204, body = "" }))
        assert.are.equal(204, resp.code)
        assert.are.equal("", resp.body)
        assert.are.same({}, resp.headers)
    end)

    it("keeps a non-200 status, which the caller decides about", function()
        assert.are.equal(503, Wire.decode(Wire.encode({ code = 503, body = "" })).code)
    end)

    it("reports output that is not a response instead of crashing", function()
        -- What a subprocess that died before writing anything leaves behind.
        local resp, err = Wire.decode("")
        assert.is_nil(resp)
        assert.are.equal("malformed subprocess output", err)

        local resp2, err2 = Wire.decode(nil)
        assert.is_nil(resp2)
        assert.are.equal("no output from subprocess", err2)
    end)
end)
