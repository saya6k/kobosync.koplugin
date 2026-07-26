-- Localization for strings that live inside this plugin.
--
-- KOReader's gettext singleton only loads the core catalog, so a string a
-- plugin invents is never translated by it -- which is why "Search…" came out
-- localized (the core happens to use it) while "Show downloaded only" stayed
-- English. This is a drop-in replacement: it looks each message up in a
-- plugin-bundled table first and falls back to core gettext, which still gets
-- to handle anything shared with KOReader's own catalog.
--
-- Call sites only swap the require:
--
--     local _ = require("kobosync_gettext")
--
-- Tables are plain Lua files returning { ["English source"] = "…" }, so they
-- need no msgfmt step and can be checked by the test suite. Add a language by
-- dropping l10n/<code>.lua next to this file, where <code> is KOReader's own
-- locale code -- take it from KOReader's l10n directory rather than guessing,
-- since several carry a region (it_IT, nl_NL, ko_KR) where one might not
-- expect it.

local GetText = require("gettext")
local logger = require("logger")

-- Where this file lives, so the tables are found wherever the plugin is
-- installed.
local function this_dir()
    local source = debug.getinfo(1, "S").source
    return source:match("^@(.*)[/\\][^/\\]+$")
end

local function load_table(lang)
    -- "C", nil, or any en_* locale means "use the source strings".
    if not lang or lang == "" or lang == "C" or lang:match("^en") then
        return nil
    end
    local dir = this_dir()
    if not dir then
        return nil
    end

    local function try(code)
        local chunk = loadfile(dir .. "/l10n/" .. code .. ".lua")
        if not chunk then
            return nil
        end
        local ok, tbl = pcall(chunk)
        if ok and type(tbl) == "table" then
            return tbl
        end
        logger.warn("kobosync_gettext: could not load l10n/" .. code .. ".lua", tbl)
        return nil
    end

    -- Exact locale first, then the bare language, so pt_PT still gets something
    -- when only pt_BR is bundled.
    return try(lang) or (lang:match("^(%a%a)") ~= lang and try(lang:match("^(%a%a)"))) or nil
end

local translation = load_table(GetText.current_lang) or {}

-- Callable table, so `_("…")` works. Field reads (_.current_lang, _.pgettext)
-- fall through to core GetText.
return setmetatable({}, {
    __call = function(_self, msgid)
        return translation[msgid] or GetText(msgid)
    end,
    __index = GetText,
})
