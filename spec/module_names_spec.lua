-- Every module this plugin ships must carry the plugin's own prefix.
--
-- KOReader puts each plugin's directory on one shared package.path, so
-- require("covermenu") resolves to whichever plugin's file is found first.
-- Shipping a generic name does not merely risk being shadowed -- it shadows
-- everyone else. That is not hypothetical: a file called covermenu.lua here was
-- picked up by KOReader's own CoverBrowser, which does
--
--     FileChooser.updateItems = require("covermenu").updateItems
--
-- and every file-manager redraw then called into this plugin with a FileChooser
-- as self, taking KOReader down at startup with an error that named neither
-- plugin.
--
-- main.lua and _meta.lua are loaded by path by the plugin loader, never by
-- require, so they keep their required names.

local lfs = require("lfs")

local LOADED_BY_PATH = {
    ["main.lua"] = true,
    ["_meta.lua"] = true,
}

-- CI installs Lua into a ".lua" directory beside the sources, so an entry that
-- ends in .lua is not necessarily one of ours, nor even a file.
local function is_source(entry)
    return entry:match("%.lua$")
        and not entry:match("^%.")
        and lfs.attributes(entry, "mode") == "file"
end

describe("module names", function()
    it("are all prefixed, so no other plugin can pick them up by accident", function()
        local checked = 0
        for entry in lfs.dir(".") do
            if is_source(entry) and not LOADED_BY_PATH[entry] then
                checked = checked + 1
                assert.is_truthy(entry:match("^kobosync_"),
                    entry .. " must be named kobosync_" .. entry
                    .. ": a bare name is shared with every other plugin")
            end
        end
        assert.is_true(checked > 0, "found no modules to check")
    end)

    it("are required under those names", function()
        for entry in lfs.dir(".") do
            if is_source(entry) then
                local file = assert(io.open(entry, "r"))
                local source = file:read("*a")
                file:close()
                for required in source:gmatch('require%("([%w_]+)"%)') do
                    -- Our own modules are always required by their prefixed
                    -- name; a bare one that happens to match a file here would
                    -- resolve to whatever else answers to it first.
                    if not required:match("^kobosync_") then
                        assert.is_nil(lfs.attributes(required .. ".lua"),
                            entry .. " requires \"" .. required
                            .. "\", which is also a file here: use the prefixed name")
                    end
                end
            end
        end
    end)
end)
