-- Mirrors server shelves (Kobo "tags") into KOReader collections. Pure logic:
-- KOReader's ReadCollection is passed in, along with a realpath function, so
-- this module has no KOReader dependencies of its own.
--
-- A collection holds the downloaded members of its shelf. Books the user put
-- in it by hand are never removed: only files this module added earlier, as
-- recorded in the applied state the caller keeps between runs, are taken out
-- again.

local Collections = {}

-- Catalog books by uuid and by revision id. calibre-web names shelf members by
-- the book uuid, which is the catalog key; a server that sends a real revision
-- id still resolves through the second index.
local function index_books(books)
    local by_uuid, by_revision = {}, {}
    for _idx, book in ipairs(books) do
        by_uuid[book.uuid] = book
        if book.revision_id then
            by_revision[book.revision_id] = book
        end
    end
    return by_uuid, by_revision
end

-- What each shelf should hold on this device: { [tag_id] = { name, files } },
-- files being a set of real paths. ReadCollection keys its entries by real
-- path, so comparing anything else would miss through a symlinked folder.
function Collections.desired(store, realpath)
    local by_uuid, by_revision = index_books(store:list_books())
    local desired = {}
    for id, tag in pairs(store:tags()) do
        local files = {}
        for _idx, member in ipairs(tag.books or {}) do
            local book = by_uuid[member] or by_revision[member]
            local path = book and book.downloaded and book.local_path
            path = path and realpath(path)
            if path then
                files[path] = true
            end
        end
        desired[id] = { name = tag.name, files = files }
    end
    return desired
end

local function as_sorted_list(set)
    local list = {}
    for value in pairs(set) do
        table.insert(list, value)
    end
    table.sort(list)
    return list
end

-- Takes the files this module added back out of a collection, and drops the
-- collection once it is empty -- but only one this module created, so a
-- collection the user made, or the default favorites, always stays.
local function release(rc, prev, changed)
    local coll = rc.coll[prev.name]
    if not coll then return end
    for _idx, file in ipairs(prev.files or {}) do
        if coll[file] then
            rc:removeItem(file, prev.name, true)
            changed[prev.name] = true
        end
    end
    if prev.created and next(coll) == nil then
        rc:removeCollection(prev.name)
        changed[prev.name] = true
    end
end

-- Brings rc in line with `desired`, given what the previous run applied.
-- Writes the collection file only when something changed, and returns the new
-- applied state for the caller to store.
--
-- A shelf with nothing downloaded gets no collection: on demand, most shelves
-- would otherwise show up as empty collections. It appears with the first
-- book downloaded from it.
function Collections.apply(rc, desired, applied)
    applied = applied or {}
    local changed = {}
    local next_applied = {}
    for id, want in pairs(desired) do
        local prev = applied[id]
        local name = want.name
        local created = prev and prev.created or false
        if prev and prev.name ~= name then
            -- Renamed on the server. Carry the collection over when it is ours
            -- and the new name is free; otherwise leave the old one as the user
            -- has it, minus what this module put there.
            if prev.created and rc.coll[prev.name] and not rc.coll[name] then
                rc:renameCollection(prev.name, name)
                changed[prev.name] = true
                changed[name] = true
            else
                release(rc, prev, changed)
                created = false
            end
            prev = { name = name, files = prev.files, created = created }
        end
        if not rc.coll[name] and next(want.files) ~= nil then
            rc:addCollection(name)
            created = true
            changed[name] = true
        end
        local coll = rc.coll[name]
        if coll then
            for file in pairs(want.files) do
                if not coll[file] then
                    rc:addItem(file, name)
                    changed[name] = true
                end
            end
            if prev then
                local stale = {}
                for _idx, file in ipairs(prev.files or {}) do
                    if not want.files[file] then
                        table.insert(stale, file)
                    end
                end
                release(rc, { name = name, files = stale, created = created }, changed)
                if not rc.coll[name] then
                    created = false
                end
            end
            next_applied[id] = { name = name, created = created, files = as_sorted_list(want.files) }
        end
    end
    for id, prev in pairs(applied) do
        if not desired[id] then
            release(rc, prev, changed)
        end
    end
    if next(changed) ~= nil then
        rc:write(changed)
    end
    return next_applied
end

return Collections
