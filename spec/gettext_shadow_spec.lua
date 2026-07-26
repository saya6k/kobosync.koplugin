-- Guards against a class of bug the compiler and luacheck both wave through.
--
-- KOReader's gettext is bound as `local _`, and `for _, x in ipairs(t)` rebinds
-- that name to the loop index inside the body. Any `_("...")` in such a loop
-- then calls a number. It crashed the browser once, when a column-picker label
-- was built inside `for _, cols in ...`.
--
-- Rather than hunt for calls inside loops, the rule is blunt: a file that binds
-- gettext does not get to use `_` as a loop variable. Pure modules, which bind
-- no gettext, are unaffected.

local SOURCES = {
    "_meta.lua",
    "browser.lua",
    "covermenu.lua",
    "koboapi.lua",
    "kobosync_gettext.lua",
    "main.lua",
    "readingstate.lua",
    "statestore.lua",
    "syncengine.lua",
    "syncindicator.lua",
    "wire.lua",
}

local function read(path)
    local file = io.open(path, "r")
    if not file then return nil end
    local contents = file:read("*a")
    file:close()
    return contents
end

describe("gettext binding", function()
    it("covers every source file, so a new one cannot slip past this check", function()
        for _idx, path in ipairs(SOURCES) do
            assert.is_truthy(read(path), path .. " is listed but missing")
        end
    end)

    it("is never shadowed by a loop variable", function()
        for _idx, path in ipairs(SOURCES) do
            local source = read(path)
            if source and source:find('local _ = require("kobosync_gettext")', 1, true) then
                local line_number = 0
                for line in source:gmatch("[^\n]*") do
                    line_number = line_number + 1
                    assert.is_nil(line:match("for%s+_%s*,"),
                        string.format("%s:%d shadows gettext with a loop variable: %s",
                            path, line_number, line))
                end
            end
        end
    end)
end)
