-- Sanity check for the plugin scaffold: _meta.lua must load outside KOReader
-- with only KOReader's own modules stubbed, and expose the fields
-- appstore.koplugin verifies. It goes through kobosync_gettext, so this also
-- exercises that the wrapper loads and resolves a message.
describe("_meta", function()
    local meta

    setup(function()
        package.preload["gettext"] = function()
            return setmetatable({ current_lang = "en" }, {
                __call = function(_self, msgid) return msgid end,
            })
        end
        package.preload["logger"] = function()
            return { warn = function() end, dbg = function() end, info = function() end }
        end
        meta = dofile("_meta.lua")
    end)

    it("declares the plugin name", function()
        assert.are.equal("kobosync", meta.name)
    end)

    it("has fullname and description", function()
        assert.is_string(meta.fullname)
        assert.is_string(meta.description)
        assert.is_true(#meta.description > 0)
    end)
end)
