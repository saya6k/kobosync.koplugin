-- Sanity check for the plugin scaffold: _meta.lua must load outside KOReader
-- with only gettext stubbed, and expose the fields appstore.koplugin verifies.
describe("_meta", function()
    local meta

    setup(function()
        package.preload["gettext"] = function()
            return function(s) return s end
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
