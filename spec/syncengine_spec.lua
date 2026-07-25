local json = require("dkjson")
local StateStore = dofile("statestore.lua")
local SyncEngine = dofile("syncengine.lua")

local function new_store()
    local path = os.tmpname()
    os.remove(path)
    return StateStore.new{ path = path, json = json }
end

local function entitlement(uuid, opts)
    opts = opts or {}
    return {
        BookEntitlement = {
            Id = uuid,
            IsRemoved = opts.removed or false,
            RevisionId = opts.revision or uuid,
            LastModified = opts.last_modified or "2026-07-25T00:00:00Z",
        },
        BookMetadata = {
            EntitlementId = uuid,
            Title = opts.title or "Some Title",
            Contributors = opts.contributors or { "Author One" },
            RevisionId = opts.revision or uuid,
            DownloadUrls = opts.download_urls or {
                { Format = "KEPUB", Url = "https://s/dl/" .. uuid .. "/kepub", Size = opts.size or 1000 },
            },
            Series = opts.series,
        },
        ReadingState = opts.reading_state,
    }
end

describe("SyncEngine.process_items", function()
    it("stores new entitlements in the catalog", function()
        local store = new_store()
        local result = SyncEngine.new_result()
        SyncEngine.process_items(store, {
            { NewEntitlement = entitlement("u1", {
                title = "괴담 25화", contributors = { "백덕수" },
                series = { Name = "괴담", Number = 25.0, NumberFloat = 25.0 },
            }) },
            { NewEntitlement = entitlement("u2") },
        }, result)
        assert.are.equal(2, result.new)
        local book = store:get_book("u1")
        assert.are.equal("괴담 25화", book.title)
        assert.are.equal("백덕수", book.author)
        assert.are.equal("괴담", book.series_name)
        assert.are.equal(25.0, book.series_number)
        assert.is_truthy(book.download_urls)
    end)

    it("joins multiple contributors", function()
        local store = new_store()
        SyncEngine.process_items(store, {
            { NewEntitlement = entitlement("u1", { contributors = { "A", "B" } }) },
        }, SyncEngine.new_result())
        assert.are.equal("A, B", store:get_book("u1").author)
    end)

    it("updates catalog on changed entitlements without wiping local fields", function()
        local store = new_store()
        store:upsert_book("u1", { downloaded = true, local_path = "/b/x.epub" })
        local result = SyncEngine.new_result()
        SyncEngine.process_items(store, {
            { ChangedEntitlement = entitlement("u1", { title = "New Title" }) },
        }, result)
        assert.are.equal(1, result.changed)
        local book = store:get_book("u1")
        assert.are.equal("New Title", book.title)
        assert.is_true(book.downloaded)
        assert.are.equal("/b/x.epub", book.local_path)
    end)

    it("queues downloaded removed books for confirmation, drops undownloaded silently", function()
        local store = new_store()
        store:upsert_book("kept", { title = "Kept", downloaded = true, local_path = "/b/kept.epub" })
        store:upsert_book("ghost", { title = "Ghost", downloaded = false })
        local result = SyncEngine.new_result()
        SyncEngine.process_items(store, {
            { ChangedEntitlement = entitlement("kept", { removed = true }) },
            { ChangedEntitlement = entitlement("ghost", { removed = true }) },
        }, result)
        assert.are.equal(2, result.removed)
        assert.are.equal(1, #result.delete_candidates)
        assert.are.equal("kept", result.delete_candidates[1].uuid)
        assert.are.equal("/b/kept.epub", result.delete_candidates[1].local_path)
        -- kept stays in catalog until the user confirms; ghost is gone
        assert.is_truthy(store:get_book("kept"))
        assert.is_nil(store:get_book("ghost"))
    end)

    it("applies ChangedReadingState to the catalog", function()
        local store = new_store()
        store:upsert_book("u1", { title = "A" })
        local result = SyncEngine.new_result()
        SyncEngine.process_items(store, {
            { ChangedReadingState = { ReadingState = {
                EntitlementId = "u1",
                LastModified = "2026-07-24T03:12:25Z",
                CurrentBookmark = { ProgressPercent = 3.72 },
            } } },
        }, result)
        assert.are.equal(1, result.states)
        assert.are.equal(3.72, store:get_book("u1").server_state.CurrentBookmark.ProgressPercent)
    end)

    it("ignores tags and unknown item types", function()
        local store = new_store()
        local result = SyncEngine.new_result()
        SyncEngine.process_items(store, {
            { DeletedTag = { Tag = { Id = "t1" } } },
            { NewTag = { Tag = { Id = "t2" } } },
            { SomethingFromTheFuture = { Whatever = true } },
        }, result)
        assert.are.equal(0, result.new + result.changed + result.states + result.removed)
    end)
end)

describe("SyncEngine.pick_download", function()
    it("prefers epub over kepub", function()
        local pick = SyncEngine.pick_download({
            { Format = "KEPUB", Url = "u-kepub" },
            { Format = "EPUB3", Url = "u-epub3" },
        })
        assert.are.equal("u-epub3", pick.Url)
    end)

    it("falls back to kepub when that is all the server offers", function()
        local pick = SyncEngine.pick_download({
            { Format = "KEPUB", Url = "u-kepub", Size = 44793 },
        })
        assert.are.equal("KEPUB", pick.Format)
    end)

    it("returns nil for missing or unusable urls", function()
        assert.is_nil(SyncEngine.pick_download(nil))
        assert.is_nil(SyncEngine.pick_download({}))
        assert.is_nil(SyncEngine.pick_download({ { Format = "PDF", Url = "u" } }))
    end)
end)

describe("SyncEngine filenames", function()
    it("builds sanitized names and keeps unicode", function()
        assert.are.equal("괴담_ 출근 - 백덕수",
            SyncEngine.sanitize_filename('괴담: 출근', "백덕수"))
        assert.are.equal("a_b_c_d", SyncEngine.sanitize_filename("a/b\\c*d", nil))
        assert.are.equal("Untitled", SyncEngine.sanitize_filename(nil, nil))
        assert.are.equal("_hidden", SyncEngine.sanitize_filename(".hidden", nil))
    end)

    it("truncates long titles at utf8 boundaries", function()
        local long = string.rep("가", 100) -- 300 bytes
        local name = SyncEngine.sanitize_filename(long, nil)
        assert.is_true(#name <= 120)
        assert.are.equal(0, #name % 3) -- no split hangul sequence
    end)

    it("maps kepub format to the kepub.epub extension", function()
        assert.are.equal(".kepub.epub", SyncEngine.extension_for("KEPUB"))
        assert.are.equal(".epub", SyncEngine.extension_for("EPUB3"))
    end)

    it("resolves collisions with a uuid suffix", function()
        local taken = { ["A.epub"] = true }
        local name = SyncEngine.unique_filename("A", ".epub", "12345678-x", function(n) return taken[n] end)
        assert.are.equal("A [12345678].epub", name)
        assert.are.equal("B.epub",
            SyncEngine.unique_filename("B", ".epub", "12345678-x", function(n) return taken[n] end))
    end)
end)

describe("SyncEngine.plan_downloads", function()
    local function seed(store)
        SyncEngine.process_items(store, {
            { NewEntitlement = entitlement("u1", { title = "A" }) },
            { NewEntitlement = entitlement("u2", { title = "B" }) },
        }, SyncEngine.new_result())
    end

    it("auto mode downloads everything not yet downloaded", function()
        local store = new_store()
        seed(store)
        local plan = SyncEngine.plan_downloads(store, "auto")
        assert.are.equal(2, #plan)
        assert.are.equal("A", plan[1].title)
        assert.are.equal("KEPUB", plan[1].format)
    end)

    it("on_demand mode downloads nothing new", function()
        local store = new_store()
        seed(store)
        assert.are.equal(0, #SyncEngine.plan_downloads(store, "on_demand"))
    end)

    it("re-downloads a downloaded book when the file size changed (calibre-web keeps RevisionId constant)", function()
        local store = new_store()
        seed(store)
        store:upsert_book("u1", { downloaded = true, downloaded_revision = "u1", downloaded_size = 1000 })
        -- same revision, changed size -> stale
        SyncEngine.process_items(store, {
            { ChangedEntitlement = entitlement("u1", { size = 2222 }) },
        }, SyncEngine.new_result())
        local plan = SyncEngine.plan_downloads(store, "on_demand")
        assert.are.equal(1, #plan)
        assert.are.equal("u1", plan[1].uuid)
        assert.is_true(plan[1].redownload)
    end)

    it("does not re-download when nothing changed", function()
        local store = new_store()
        seed(store)
        store:upsert_book("u1", { downloaded = true, downloaded_revision = "u1", downloaded_size = 1000 })
        store:upsert_book("u2", { downloaded = true, downloaded_revision = "u2", downloaded_size = 1000 })
        assert.are.equal(0, #SyncEngine.plan_downloads(store, "auto"))
    end)
end)
