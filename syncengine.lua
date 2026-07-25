-- Sync algorithm: reduces Kobo Sync response items into catalog changes and
-- download plans. Pure logic: no KOReader dependencies, no I/O.

local SyncEngine = {}

-- Format preference per SPEC: native epub first, kepub accepted as fallback.
local FORMAT_PREFERENCE = { "EPUB3", "EPUB", "EPUB3FL", "KEPUB" }

function SyncEngine.new_result()
    return {
        new = 0,
        changed = 0,
        states = 0,
        removed = 0,
        delete_candidates = {},
    }
end

local function join_contributors(contributors)
    if type(contributors) ~= "table" or #contributors == 0 then return nil end
    return table.concat(contributors, ", ")
end

local function entitlement_uuid(e)
    if e.BookMetadata and e.BookMetadata.EntitlementId then
        return e.BookMetadata.EntitlementId
    end
    if e.BookEntitlement and e.BookEntitlement.Id then
        return e.BookEntitlement.Id
    end
    return nil
end

local function process_entitlement(store, e, is_new, result)
    local uuid = entitlement_uuid(e)
    if not uuid then return end
    local be = e.BookEntitlement or {}
    if be.IsRemoved then
        local entry = store:get_book(uuid)
        if entry and entry.downloaded and entry.local_path then
            -- Never delete local files without user confirmation.
            table.insert(result.delete_candidates, {
                uuid = uuid,
                title = entry.title,
                local_path = entry.local_path,
            })
        else
            store:remove_book(uuid)
        end
        result.removed = result.removed + 1
        return
    end
    local bm = e.BookMetadata or {}
    local fields = {
        title = bm.Title,
        author = join_contributors(bm.Contributors),
        download_urls = bm.DownloadUrls,
        revision_id = bm.RevisionId or be.RevisionId,
        last_modified = be.LastModified,
    }
    if type(bm.Series) == "table" then
        fields.series_name = bm.Series.Name
        fields.series_number = bm.Series.NumberFloat or bm.Series.Number
    end
    if e.ReadingState then
        fields.server_state = e.ReadingState
    end
    store:upsert_book(uuid, fields)
    if is_new then
        result.new = result.new + 1
    else
        result.changed = result.changed + 1
    end
end

-- Processes one page of sync items into the store, accumulating into result
-- (from new_result()). Unknown item types and fields are ignored.
function SyncEngine.process_items(store, items, result)
    for _, item in ipairs(items) do
        if item.NewEntitlement then
            process_entitlement(store, item.NewEntitlement, true, result)
        elseif item.ChangedEntitlement then
            process_entitlement(store, item.ChangedEntitlement, false, result)
        elseif item.ChangedReadingState then
            local state = item.ChangedReadingState.ReadingState
            if state and state.EntitlementId then
                store:upsert_book(state.EntitlementId, { server_state = state })
                result.states = result.states + 1
            end
        end
        -- NewTag/ChangedTag/DeletedTag and anything else: ignored in v1.
    end
    return result
end

-- Picks the preferred download among BookMetadata.DownloadUrls.
-- Returns { Format = ..., Url = ..., Size = ... } or nil.
function SyncEngine.pick_download(download_urls)
    if type(download_urls) ~= "table" then return nil end
    for _, wanted in ipairs(FORMAT_PREFERENCE) do
        for _, d in ipairs(download_urls) do
            if d.Format == wanted and d.Url then
                return d
            end
        end
    end
    return nil
end

function SyncEngine.extension_for(format)
    if format == "KEPUB" then
        return ".kepub.epub"
    end
    return ".epub"
end

-- Truncates a UTF-8 string to at most max_bytes without splitting a
-- character sequence.
local function utf8_truncate(s, max_bytes)
    if #s <= max_bytes then return s end
    local out, len = {}, 0
    for char in s:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        len = len + #char
        if len > max_bytes then break end
        table.insert(out, char)
    end
    return table.concat(out)
end

-- "<Title> - <Author>" with filesystem-hostile characters replaced.
function SyncEngine.sanitize_filename(title, author)
    local base = title or "Untitled"
    if author and author ~= "" then
        base = base .. " - " .. author
    end
    base = base:gsub("[/\\:%*%?\"<>|%c]", "_")
    base = base:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    base = base:gsub("^%.+", "_") -- no hidden/dot-relative names
    return utf8_truncate(base, 120)
end

-- Resolves filename collisions: exists_fn(name) says whether a candidate is
-- already taken by a different book. uuid keeps the fallback deterministic.
function SyncEngine.unique_filename(base, ext, uuid, exists_fn)
    local name = base .. ext
    if not exists_fn(name) then return name end
    name = base .. " [" .. uuid:sub(1, 8) .. "]" .. ext
    return name
end

-- Computes which catalog books need downloading.
-- mode "auto": every book we do not have yet, plus stale re-downloads.
-- mode "on_demand": stale re-downloads only (of books the user already has).
-- A downloaded book is stale when the server revision or file size changed.
function SyncEngine.plan_downloads(store, mode)
    local plan = {}
    for _, book in ipairs(store:list_books()) do
        local pick = SyncEngine.pick_download(book.download_urls)
        if pick then
            local want
            if book.downloaded then
                want = (book.downloaded_revision ~= book.revision_id)
                    or (book.downloaded_size ~= pick.Size)
            else
                want = mode == "auto"
            end
            if want then
                table.insert(plan, {
                    uuid = book.uuid,
                    title = book.title,
                    url = pick.Url,
                    format = pick.Format,
                    size = pick.Size,
                    revision_id = book.revision_id,
                    redownload = book.downloaded or false,
                })
            end
        end
    end
    table.sort(plan, function(a, b) return (a.title or "") < (b.title or "") end)
    return plan
end

return SyncEngine
