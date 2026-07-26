local json = require("dkjson")
local StateStore = dofile("statestore.lua")

describe("StateStore", function()
    local path

    before_each(function()
        path = os.tmpname()
        os.remove(path) -- start from a missing file
    end)

    after_each(function()
        os.remove(path)
        os.remove(path .. ".tmp")
    end)

    local function new_store()
        return StateStore.new{ path = path, json = json }
    end

    it("starts empty when the file does not exist", function()
        local store = new_store()
        assert.is_nil(store:get_synctoken())
        assert.are.same({}, store:list_books())
    end)

    it("round-trips synctoken, catalog and pending states", function()
        local store = new_store()
        store:set_synctoken("z1:opaque==")
        store:upsert_book("uuid-1", {
            title = "어떤 제목 — 25화?!",
            author = "작자/미상 <테스트>",
            revision_id = "rev-1",
            downloaded = false,
        })
        store:set_pending_state("uuid-1", { ProgressPercent = 42.5 })
        assert.is_truthy(store:save())

        local reloaded = new_store()
        assert.are.equal("z1:opaque==", reloaded:get_synctoken())
        local book = reloaded:get_book("uuid-1")
        assert.are.equal("어떤 제목 — 25화?!", book.title)
        assert.are.equal("작자/미상 <테스트>", book.author)
        assert.is_false(book.downloaded)
        assert.are.equal(42.5, reloaded:pending_states()["uuid-1"].ProgressPercent)
    end)

    it("upsert merges fields without wiping local ones", function()
        local store = new_store()
        store:upsert_book("uuid-1", { title = "Old", local_path = "/books/a.kepub.epub", downloaded = true })
        store:upsert_book("uuid-1", { title = "New", revision_id = "rev-2" })
        local book = store:get_book("uuid-1")
        assert.are.equal("New", book.title)
        assert.are.equal("/books/a.kepub.epub", book.local_path)
        assert.is_true(book.downloaded)
        assert.are.equal("rev-2", book.revision_id)
    end)

    it("remove_book drops the entry and its pending state", function()
        local store = new_store()
        store:upsert_book("uuid-1", { title = "A" })
        store:set_pending_state("uuid-1", { ProgressPercent = 10 })
        store:remove_book("uuid-1")
        assert.is_nil(store:get_book("uuid-1"))
        assert.is_nil(store:pending_states()["uuid-1"])
    end)

    it("falls back to an empty store on a corrupt file", function()
        local f = assert(io.open(path, "w"))
        f:write("{ this is not JSON !!!")
        f:close()
        local store = new_store()
        assert.is_nil(store:get_synctoken())
        assert.are.same({}, store:list_books())
    end)

    it("falls back to an empty store on valid JSON with a foreign shape", function()
        local f = assert(io.open(path, "w"))
        f:write('["some", "array"]')
        f:close()
        local store = new_store()
        assert.are.same({}, store:list_books())
    end)

    it("reset clears everything", function()
        local store = new_store()
        store:set_synctoken("tok")
        store:upsert_book("uuid-1", { title = "A" })
        store:reset()
        assert.is_nil(store:get_synctoken())
        assert.are.same({}, store:list_books())
    end)

    it("list_books includes the uuid on each item", function()
        local store = new_store()
        store:upsert_book("uuid-1", { title = "A" })
        store:upsert_book("uuid-2", { title = "B" })
        local books = store:list_books()
        assert.are.equal(2, #books)
        local seen = {}
        for _, b in ipairs(books) do seen[b.uuid] = b.title end
        assert.are.equal("A", seen["uuid-1"])
        assert.are.equal("B", seen["uuid-2"])
    end)
end)
