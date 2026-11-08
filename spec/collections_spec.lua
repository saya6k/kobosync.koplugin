local json = require("dkjson")
local Collections = dofile("kobosync_collections.lua")
local StateStore = dofile("kobosync_statestore.lua")

local function new_store()
    local path = os.tmpname()
    os.remove(path)
    return StateStore.new{ path = path, json = json }
end

local function identity(path) return path end

-- The parts of KOReader's ReadCollection this module touches, keyed the same
-- way: rc.coll[name][file] = item. write() records what it was asked to write.
local function fake_rc(initial)
    local rc = { coll = {}, coll_settings = {}, writes = {} }
    for name, files in pairs(initial or {}) do
        rc.coll[name] = {}
        rc.coll_settings[name] = { order = 1 }
        for _idx, file in ipairs(files) do
            rc.coll[name][file] = { file = file }
        end
    end
    function rc:addCollection(name)
        self.coll[name] = {}
        self.coll_settings[name] = { order = 1 }
    end
    function rc:renameCollection(name, new_name)
        self.coll[new_name], self.coll[name] = self.coll[name], nil
        self.coll_settings[new_name], self.coll_settings[name] = self.coll_settings[name], nil
    end
    function rc:removeCollection(name)
        self.coll[name] = nil
        self.coll_settings[name] = nil
    end
    function rc:addItem(file, name)
        self.coll[name][file] = { file = file }
    end
    function rc:removeItem(file, name, no_write)
        assert.is_true(no_write, "removeItem must not write on its own")
        self.coll[name][file] = nil
    end
    function rc:write(updated)
        table.insert(self.writes, updated)
    end
    return rc
end

local function files_of(rc, name)
    local files = {}
    for file in pairs(rc.coll[name] or {}) do
        table.insert(files, file)
    end
    table.sort(files)
    return files
end

local function sync(store, rc)
    local applied = Collections.apply(rc, Collections.desired(store, identity),
        store:applied_collections())
    store:set_applied_collections(applied)
    return applied
end

local function downloaded(store, uuid, path)
    store:upsert_book(uuid, { title = uuid, downloaded = true, local_path = path })
end

describe("Collections.desired", function()
    it("holds the downloaded members of each shelf", function()
        local store = new_store()
        downloaded(store, "u1", "/b/1.epub")
        store:upsert_book("u2", { title = "not here" })
        store:set_tag("t1", { name = "To read", books = { "u1", "u2", "unknown" } })
        local desired = Collections.desired(store, identity)
        assert.are.same({ t1 = { name = "To read", files = { ["/b/1.epub"] = true } } }, desired)
    end)

    it("resolves members named by revision id", function()
        local store = new_store()
        store:upsert_book("u1", { downloaded = true, local_path = "/b/1.epub", revision_id = "r1" })
        store:set_tag("t1", { name = "S", books = { "r1" } })
        assert.is_true(Collections.desired(store, identity).t1.files["/b/1.epub"])
    end)

    it("compares real paths and skips files that no longer resolve", function()
        local store = new_store()
        downloaded(store, "u1", "/link/1.epub")
        downloaded(store, "u2", "/link/gone.epub")
        store:set_tag("t1", { name = "S", books = { "u1", "u2" } })
        local desired = Collections.desired(store, function(path)
            if path:match("gone") then return nil end
            return (path:gsub("^/link", "/real"))
        end)
        assert.are.same({ ["/real/1.epub"] = true }, desired.t1.files)
    end)
end)

describe("Collections.apply", function()
    it("creates a collection per shelf and writes once", function()
        local store, rc = new_store(), fake_rc()
        downloaded(store, "u1", "/b/1.epub")
        downloaded(store, "u2", "/b/2.epub")
        store:set_tag("t1", { name = "To read", books = { "u1", "u2" } })
        store:set_tag("t2", { name = "Favs", books = { "u2" } })
        sync(store, rc)
        assert.are.same({ "/b/1.epub", "/b/2.epub" }, files_of(rc, "To read"))
        assert.are.same({ "/b/2.epub" }, files_of(rc, "Favs"))
        assert.are.equal(1, #rc.writes)
        assert.are.same({ ["To read"] = true, Favs = true }, rc.writes[1])
    end)

    it("does not write when nothing changed", function()
        local store, rc = new_store(), fake_rc()
        downloaded(store, "u1", "/b/1.epub")
        store:set_tag("t1", { name = "To read", books = { "u1" } })
        sync(store, rc)
        sync(store, rc)
        assert.are.equal(1, #rc.writes)
    end)

    it("makes no collection for a shelf with nothing on the device", function()
        local store, rc = new_store(), fake_rc()
        store:upsert_book("u1", { title = "remote only" })
        store:set_tag("t1", { name = "To read", books = { "u1" } })
        sync(store, rc)
        assert.is_nil(rc.coll["To read"])
        assert.are.equal(0, #rc.writes)
        -- ...and makes one with the first download.
        downloaded(store, "u1", "/b/1.epub")
        sync(store, rc)
        assert.are.same({ "/b/1.epub" }, files_of(rc, "To read"))
    end)

    it("takes out books that left the shelf but keeps ones the user added", function()
        local store, rc = new_store(), fake_rc()
        downloaded(store, "u1", "/b/1.epub")
        downloaded(store, "u2", "/b/2.epub")
        store:set_tag("t1", { name = "To read", books = { "u1", "u2" } })
        sync(store, rc)
        rc:addItem("/b/mine.epub", "To read")
        store:set_tag("t1", { name = "To read", books = { "u2" } })
        sync(store, rc)
        assert.are.same({ "/b/2.epub", "/b/mine.epub" }, files_of(rc, "To read"))
    end)

    it("merges into an existing collection of the same name and never removes it", function()
        local store, rc = new_store(), fake_rc({ favorites = { "/b/mine.epub" } })
        downloaded(store, "u1", "/b/1.epub")
        store:set_tag("t1", { name = "favorites", books = { "u1" } })
        sync(store, rc)
        assert.are.same({ "/b/1.epub", "/b/mine.epub" }, files_of(rc, "favorites"))
        store:remove_tag("t1")
        sync(store, rc)
        assert.are.same({ "/b/mine.epub" }, files_of(rc, "favorites"))
        rc:removeItem("/b/mine.epub", "favorites", true)
        store:set_tag("t1", { name = "favorites", books = { "u1" } })
        sync(store, rc)
        store:remove_tag("t1")
        sync(store, rc)
        assert.is_truthy(rc.coll.favorites, "a collection the user had must survive emptying")
    end)

    it("removes a collection it created once the shelf is deleted", function()
        local store, rc = new_store(), fake_rc()
        downloaded(store, "u1", "/b/1.epub")
        store:set_tag("t1", { name = "To read", books = { "u1" } })
        sync(store, rc)
        store:remove_tag("t1")
        local applied = sync(store, rc)
        assert.is_nil(rc.coll["To read"])
        assert.are.same({}, applied)
    end)

    it("keeps a created collection the user has added books to", function()
        local store, rc = new_store(), fake_rc()
        downloaded(store, "u1", "/b/1.epub")
        store:set_tag("t1", { name = "To read", books = { "u1" } })
        sync(store, rc)
        rc:addItem("/b/mine.epub", "To read")
        store:remove_tag("t1")
        sync(store, rc)
        assert.are.same({ "/b/mine.epub" }, files_of(rc, "To read"))
    end)

    it("removes a created collection whose last book is no longer downloaded", function()
        local store, rc = new_store(), fake_rc()
        downloaded(store, "u1", "/b/1.epub")
        store:set_tag("t1", { name = "To read", books = { "u1" } })
        sync(store, rc)
        store:upsert_book("u1", { downloaded = false })
        sync(store, rc)
        assert.is_nil(rc.coll["To read"])
    end)

    it("renames a collection it created along with the shelf", function()
        local store, rc = new_store(), fake_rc()
        downloaded(store, "u1", "/b/1.epub")
        store:set_tag("t1", { name = "To read", books = { "u1" } })
        sync(store, rc)
        rc:addItem("/b/mine.epub", "To read")
        store:set_tag("t1", { name = "Reading", books = { "u1" } })
        local applied = sync(store, rc)
        assert.is_nil(rc.coll["To read"])
        assert.are.same({ "/b/1.epub", "/b/mine.epub" }, files_of(rc, "Reading"))
        assert.are.equal("Reading", applied.t1.name)
        assert.is_true(applied.t1.created)
    end)

    it("leaves a user's collection behind when its shelf is renamed", function()
        local store, rc = new_store(), fake_rc({ ["To read"] = { "/b/mine.epub" } })
        downloaded(store, "u1", "/b/1.epub")
        store:set_tag("t1", { name = "To read", books = { "u1" } })
        sync(store, rc)
        store:set_tag("t1", { name = "Reading", books = { "u1" } })
        local applied = sync(store, rc)
        assert.are.same({ "/b/mine.epub" }, files_of(rc, "To read"))
        assert.are.same({ "/b/1.epub" }, files_of(rc, "Reading"))
        assert.is_true(applied.t1.created)
    end)

    it("does not rename onto a collection that already exists", function()
        local store, rc = new_store(), fake_rc({ Reading = { "/b/mine.epub" } })
        downloaded(store, "u1", "/b/1.epub")
        store:set_tag("t1", { name = "To read", books = { "u1" } })
        sync(store, rc)
        store:set_tag("t1", { name = "Reading", books = { "u1" } })
        local applied = sync(store, rc)
        assert.is_nil(rc.coll["To read"])
        assert.are.same({ "/b/1.epub", "/b/mine.epub" }, files_of(rc, "Reading"))
        assert.is_false(applied.t1.created)
    end)

    it("recreates a collection the user deleted while the shelf still has books", function()
        local store, rc = new_store(), fake_rc()
        downloaded(store, "u1", "/b/1.epub")
        store:set_tag("t1", { name = "To read", books = { "u1" } })
        sync(store, rc)
        rc:removeCollection("To read")
        sync(store, rc)
        assert.are.same({ "/b/1.epub" }, files_of(rc, "To read"))
    end)
end)
