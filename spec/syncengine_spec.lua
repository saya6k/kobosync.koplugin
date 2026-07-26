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

describe("SyncEngine.short_title", function()
    it("drops a repeated series prefix, as calibre-web sends it for chapters", function()
        assert.are.equal("Chapter 25",
            SyncEngine.short_title("S - S Chapter 25", "S"))
    end)

    it("drops a single series prefix", function()
        assert.are.equal("Chapter 3", SyncEngine.short_title("S - Chapter 3", "S"))
    end)

    it("handles en dash and colon separators", function()
        assert.are.equal("3", SyncEngine.short_title("S – 3", "S"))
        assert.are.equal("3", SyncEngine.short_title("S: 3", "S"))
    end)

    it("strips a multi-byte prefix without splitting characters", function()
        assert.are.equal("3", SyncEngine.short_title("가나 - 3", "가나"))
        -- "가" and "가나" share a leading byte; the shorter name must not match.
        assert.are.equal("가나 - 3", SyncEngine.short_title("가나 - 3", "다라"))
    end)

    it("keeps the title when stripping would leave nothing", function()
        assert.are.equal("S", SyncEngine.short_title("S", "S"))
        assert.are.equal("S -", SyncEngine.short_title("S -", "S"))
    end)

    it("only strips at a separator or space, never mid-word", function()
        assert.are.equal("Some Book", SyncEngine.short_title("Some Book", "S"))
        assert.are.equal("가나다 이야기", SyncEngine.short_title("가나다 이야기", "가나"))
    end)

    it("leaves unrelated titles and missing series alone", function()
        assert.are.equal("Some Book", SyncEngine.short_title("Some Book", nil))
        assert.are.equal("Some Book", SyncEngine.short_title("Some Book", ""))
    end)
end)

describe("SyncEngine.group_by_series", function()
    local function book(uuid, opts)
        opts = opts or {}
        return {
            uuid = uuid,
            title = opts.title or uuid,
            series_name = opts.series,
            series_number = opts.number,
            downloaded = opts.downloaded,
        }
    end

    it("groups by series and orders chapters by number, not by title", function()
        local groups, standalone = SyncEngine.group_by_series{
            book("c10", { series = "S", number = 10, title = "10화" }),
            book("c2", { series = "S", number = 2, title = "2화" }),
            book("c1", { series = "S", number = 1, title = "1화" }),
        }
        assert.are.equal(0, #standalone)
        assert.are.equal(1, #groups)
        assert.are.equal("S", groups[1].name)
        assert.are.same({ "c1", "c2", "c10" },
            { groups[1].books[1].uuid, groups[1].books[2].uuid, groups[1].books[3].uuid })
    end)

    it("sorts numeric strings as numbers", function()
        local groups = SyncEngine.group_by_series{
            book("c10", { series = "S", number = "10" }),
            book("c2", { series = "S", number = "2" }),
        }
        assert.are.equal("c2", groups[1].books[1].uuid)
    end)

    it("puts chapters without a number last, ordered by title", function()
        local groups = SyncEngine.group_by_series{
            book("z", { series = "S", title = "Zebra" }),
            book("a", { series = "S", title = "Apple" }),
            book("n", { series = "S", number = 1 }),
        }
        assert.are.same({ "n", "a", "z" },
            { groups[1].books[1].uuid, groups[1].books[2].uuid, groups[1].books[3].uuid })
    end)

    it("counts downloaded chapters per series", function()
        local groups = SyncEngine.group_by_series{
            book("c1", { series = "S", number = 1, downloaded = true }),
            book("c2", { series = "S", number = 2 }),
        }
        assert.are.equal(1, groups[1].downloaded)
        assert.are.equal(2, #groups[1].books)
    end)

    it("separates books with no series and sorts both lists by name", function()
        local groups, standalone = SyncEngine.group_by_series{
            book("b", { title = "Beta" }),
            book("a", { title = "Alpha" }),
            book("s2", { series = "Second", number = 1 }),
            book("s1", { series = "First", number = 1 }),
        }
        assert.are.same({ "First", "Second" }, { groups[1].name, groups[2].name })
        assert.are.same({ "Alpha", "Beta" }, { standalone[1].title, standalone[2].title })
    end)

    it("treats an empty series name as no series", function()
        local groups, standalone = SyncEngine.group_by_series{ book("a", { series = "" }) }
        assert.are.equal(0, #groups)
        assert.are.equal(1, #standalone)
    end)
end)

describe("SyncEngine.filter_books", function()
    local books = {
        { uuid = "a", title = "Alpha", series_name = "First" },
        { uuid = "b", title = "Beta", series_name = "Second", downloaded = true },
        { uuid = "c", title = "가나다" },
    }

    local function uuids(list)
        local out = {}
        for _, b in ipairs(list) do table.insert(out, b.uuid) end
        return out
    end

    it("returns everything when no filter is set", function()
        assert.are.same({ "a", "b", "c" }, uuids(SyncEngine.filter_books(books)))
        assert.are.same({ "a", "b", "c" }, uuids(SyncEngine.filter_books(books, { query = "" })))
    end)

    it("matches the title case-insensitively", function()
        assert.are.same({ "a" }, uuids(SyncEngine.filter_books(books, { query = "alp" })))
        assert.are.same({ "a" }, uuids(SyncEngine.filter_books(books, { query = "ALP" })))
    end)

    it("matches the series name", function()
        assert.are.same({ "b" }, uuids(SyncEngine.filter_books(books, { query = "second" })))
    end)

    it("matches multi-byte titles literally", function()
        assert.are.same({ "c" }, uuids(SyncEngine.filter_books(books, { query = "가나" })))
    end)

    it("treats the query as plain text, not a Lua pattern", function()
        local patterned = { { uuid = "p", title = "a.c" }, { uuid = "q", title = "abc" } }
        assert.are.same({ "p" }, uuids(SyncEngine.filter_books(patterned, { query = "a.c" })))
    end)

    it("keeps only downloaded books when asked", function()
        assert.are.same({ "b" }, uuids(SyncEngine.filter_books(books, { downloaded_only = true })))
    end)

    it("combines query and downloaded filter", function()
        assert.are.same({}, uuids(SyncEngine.filter_books(books, {
            query = "alpha", downloaded_only = true,
        })))
    end)
end)
