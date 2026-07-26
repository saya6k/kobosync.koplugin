-- syncindicator.lua pulls in KOReader widgets, so it cannot be loaded here.
-- What can be pinned is the one field the whole thing hinges on.
--
-- UIManager:sendEvent walks the window stack from the top and gives the event
-- to the first widget that is not a toast, whether or not that widget handles
-- it. An indicator without `toast` therefore swallows every tap in the reader
-- underneath just by being on screen -- which is what happened: page turns and
-- the menu both stopped responding, with no error anywhere to explain it.

local function read(path)
    local file = assert(io.open(path, "r"), path .. " is missing")
    local contents = file:read("*a")
    file:close()
    return contents
end

describe("SyncIndicator", function()
    local source = read("syncindicator.lua")

    it("is a toast, so it never stops event propagation", function()
        assert.is_truthy(source:match("toast%s*=%s*true"),
            "syncindicator.lua must set toast = true, or it will swallow every "
            .. "tap meant for the reader while a sync runs")
    end)

    it("leaves double tap alone", function()
        -- UIManager reads disable_double_tap off whatever it shows, and treats
        -- a missing value as "disable it".
        assert.is_truthy(source:match("disable_double_tap%s*=%s*false"),
            "syncindicator.lua must set disable_double_tap = false, or showing "
            .. "it turns double tap off in the reader underneath")
    end)

    it("registers no gestures of its own", function()
        assert.is_nil(source:match("ges_events"),
            "syncindicator.lua must not register gestures: it is meant to be "
            .. "looked at, not tapped")
    end)
end)
