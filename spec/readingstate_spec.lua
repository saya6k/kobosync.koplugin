local ReadingState = dofile("kobosync_readingstate.lua")

describe("ReadingState timestamps", function()
    it("round-trips iso <-> epoch as UTC", function()
        local iso = "2026-07-24T03:12:25Z"
        local epoch = ReadingState.iso_to_epoch(iso)
        assert.are.equal(iso, ReadingState.epoch_to_iso(epoch))
    end)

    it("returns nil for garbage", function()
        assert.is_nil(ReadingState.iso_to_epoch(nil))
        assert.is_nil(ReadingState.iso_to_epoch("not a date"))
    end)
end)

describe("ReadingState.to_kobo", function()
    local now = ReadingState.iso_to_epoch("2026-07-25T10:00:00Z")

    it("maps progress and status", function()
        local out = ReadingState.to_kobo("u1", {
            percent = 0.372, status = "reading", modified_time = now,
        })
        assert.are.equal("u1", out.EntitlementId)
        assert.are.equal("Reading", out.StatusInfo.Status)
        assert.are.equal(37.2, out.CurrentBookmark.ProgressPercent)
        assert.are.equal(37.2, out.CurrentBookmark.ContentSourceProgressPercent)
        assert.are.equal("2026-07-25T10:00:00Z", out.LastModified)
        assert.are.equal("2026-07-25T10:00:00Z", out.PriorityTimestamp)
    end)

    it("always includes the Statistics key (server rejects its absence with 400)", function()
        local out = ReadingState.to_kobo("u1", {
            percent = 0.1, status = "reading", modified_time = now,
        })
        assert.is_table(out.Statistics)
        assert.are.equal("2026-07-25T10:00:00Z", out.Statistics.LastModified)
    end)

    it("maps complete to Finished and abandoned to Reading", function()
        assert.are.equal("Finished", ReadingState.to_kobo("u", {
            percent = 1, status = "complete", modified_time = now,
        }).StatusInfo.Status)
        assert.are.equal("Reading", ReadingState.to_kobo("u", {
            percent = 0.5, status = "abandoned", modified_time = now,
        }).StatusInfo.Status)
    end)

    it("reports unstarted books as ReadyToRead", function()
        assert.are.equal("ReadyToRead", ReadingState.to_kobo("u", {
            percent = 0, modified_time = now,
        }).StatusInfo.Status)
    end)

    it("echoes the server kepub Location untouched", function()
        local loc = { Value = "span#kobo.5.1", Type = "KoboSpan", Source = "x.html" }
        local out = ReadingState.to_kobo("u", {
            percent = 0.5, status = "reading", modified_time = now,
        }, { CurrentBookmark = { Location = loc, ProgressPercent = 10 } })
        assert.are.same(loc, out.CurrentBookmark.Location)
        assert.are.equal(50, out.CurrentBookmark.ProgressPercent)
    end)
end)

describe("ReadingState.from_kobo", function()
    it("extracts percent, status and time", function()
        local st = ReadingState.from_kobo({
            EntitlementId = "u1",
            LastModified = "2026-07-24T03:12:25Z",
            StatusInfo = { Status = "Reading" },
            CurrentBookmark = { ProgressPercent = 3.72 },
        })
        assert.is_true(math.abs(st.percent - 0.0372) < 1e-9)
        assert.are.equal("reading", st.status)
        assert.are.equal(ReadingState.iso_to_epoch("2026-07-24T03:12:25Z"), st.modified_time)
    end)

    it("maps Finished to complete and ReadyToRead to nil status", function()
        assert.are.equal("complete",
            ReadingState.from_kobo({ StatusInfo = { Status = "Finished" } }).status)
        assert.is_nil(ReadingState.from_kobo({ StatusInfo = { Status = "ReadyToRead" } }).status)
    end)
end)

describe("ReadingState.resolve", function()
    local base = "2026-07-25T10:00:00Z"
    local base_epoch = ReadingState.iso_to_epoch(base)

    it("pushes when the device is newer", function()
        assert.are.equal("push", ReadingState.resolve(
            { modified_time = base_epoch + 60 },
            { LastModified = base }))
    end)

    it("pulls when the server is newer", function()
        assert.are.equal("pull", ReadingState.resolve(
            { modified_time = base_epoch - 60 },
            { LastModified = base }))
    end)

    it("does nothing within the tolerance window", function()
        assert.are.equal("noop", ReadingState.resolve(
            { modified_time = base_epoch + 3 },
            { LastModified = base }))
    end)

    it("handles missing sides", function()
        assert.are.equal("push", ReadingState.resolve({ modified_time = base_epoch }, nil))
        assert.are.equal("push", ReadingState.resolve(
            { modified_time = base_epoch }, { LastModified = nil }))
        assert.are.equal("pull", ReadingState.resolve(nil, { LastModified = base }))
        assert.are.equal("noop", ReadingState.resolve(nil, nil))
    end)
end)

describe("ReadingState.plan", function()
    local function server(iso, status)
        return {
            LastModified = iso,
            StatusInfo = { Status = status or "Reading" },
            CurrentBookmark = { ProgressPercent = 10 },
        }
    end

    it("pushes a book finished on the device", function()
        -- The case that went unnoticed: sync only ever pulled, so marking a
        -- book read never reached the server.
        local local_state = {
            percent = 1, status = "complete",
            modified_time = ReadingState.iso_to_epoch("2026-07-27T10:00:00Z"),
        }
        assert.are.equal("push",
            ReadingState.plan(local_state, server("2026-07-27T09:00:00Z"), {}))
    end)

    it("pulls when the server is ahead", function()
        local local_state = { modified_time = ReadingState.iso_to_epoch("2026-07-27T09:00:00Z") }
        assert.are.equal("pull",
            ReadingState.plan(local_state, server("2026-07-27T10:00:00Z"), {}))
    end)

    it("does not pull the same server state twice", function()
        local local_state = { modified_time = ReadingState.iso_to_epoch("2026-07-27T09:00:00Z") }
        assert.are.equal("noop", ReadingState.plan(local_state, server("2026-07-27T10:00:00Z"),
            { applied_state_time = "2026-07-27T10:00:00Z" }))
    end)

    it("does not push a sidecar it has already sent", function()
        local written = ReadingState.iso_to_epoch("2026-07-27T10:00:00Z")
        assert.are.equal("noop", ReadingState.plan(
            { modified_time = written }, server("2026-07-27T09:00:00Z"),
            { pushed_local_time = written }))
    end)

    it("does not push back what it just pulled", function()
        -- Writing the sidecar makes it newer than the state it came from, so
        -- without the mark this bounces between the two sides forever.
        local server_state = server("2026-07-27T10:00:00Z")
        local after_pull = { modified_time = ReadingState.iso_to_epoch("2026-07-27T10:30:00Z") }
        assert.are.equal("noop", ReadingState.plan(after_pull, server_state, {
            applied_state_time = "2026-07-27T10:00:00Z",
            pushed_local_time = after_pull.modified_time,
        }))
    end)

    it("pushes a book the server has never heard of", function()
        assert.are.equal("push", ReadingState.plan({ modified_time = 1000 }, nil, {}))
    end)

    it("does nothing without a local sidecar", function()
        assert.are.equal("noop", ReadingState.plan(nil, nil, {}))
    end)
end)
