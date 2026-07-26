-- Checks every bundled translation against the template.
--
-- A translation table is looked up by the exact English source string, so a key
-- that drifts by one character silently falls back to English -- no error, no
-- warning, just an untranslated string. Placeholders are worse: %1 dropped or
-- renumbered produces a message with a hole in it at runtime.

local lfs = require("lfs")

local function load_table(path)
    local chunk = assert(loadfile(path), path .. " does not load")
    local ok, tbl = pcall(chunk)
    assert(ok and type(tbl) == "table", path .. " does not return a table")
    return tbl
end

local function placeholders(text)
    local found = {}
    for digit in text:gmatch("%%(%d)") do
        found[digit] = (found[digit] or 0) + 1
    end
    return found
end

local function locales()
    local found = {}
    for entry in lfs.dir("l10n") do
        local code = entry:match("^(.+)%.lua$")
        if code and code ~= "template" then
            table.insert(found, code)
        end
    end
    table.sort(found)
    return found
end

describe("translations", function()
    local template = load_table("l10n/template.lua")
    local codes = locales()

    it("bundles the languages the plugin claims to support", function()
        assert.is_true(#codes >= 15, "expected the full set of locales, found " .. #codes)
    end)

    it("keys the template by its own English source", function()
        for key, value in pairs(template) do
            assert.are.equal(key, value, "template values must repeat the key verbatim")
        end
    end)

    for _idx, code in ipairs(locales()) do
        describe(code, function()
            local translation = load_table("l10n/" .. code .. ".lua")

            it("covers every key and invents none", function()
                for key in pairs(template) do
                    assert.is_truthy(translation[key],
                        code .. " is missing: " .. key:gsub("\n", "\\n"))
                end
                for key in pairs(translation) do
                    assert.is_truthy(template[key],
                        code .. " has a key the source no longer uses: " .. key:gsub("\n", "\\n"))
                end
            end)

            it("keeps every placeholder", function()
                for key, value in pairs(translation) do
                    assert.are.same(placeholders(key), placeholders(value),
                        code .. " changed the placeholders of: " .. key:gsub("\n", "\\n"))
                end
            end)

            it("translates something", function()
                -- A file that is a straight copy of the template is worse than
                -- no file: it hides the fallback to core gettext.
                local translated = 0
                for key, value in pairs(translation) do
                    if key ~= value then
                        translated = translated + 1
                    end
                end
                assert.is_true(translated > #codes, code .. " looks like an untouched copy")
            end)
        end)
    end
end)
