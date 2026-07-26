-- Conversion between KOReader reading progress and Kobo ReadingState JSON,
-- plus newest-wins conflict resolution. Pure logic: no KOReader dependencies.
--
-- local_state = { percent = 0..1, status = "reading"|"complete"|"abandoned"|nil,
--                 modified_time = epoch seconds }
-- server_state = Kobo ReadingState object (EntitlementId, LastModified,
--                StatusInfo, CurrentBookmark, ...)

local ReadingState = {}

-- Clock skew / second-granularity tolerance for newest-wins comparison.
local TOLERANCE_SECONDS = 5

-- os.time() interprets a table as local time; correct by the UTC offset so
-- ISO "Z" timestamps become real epochs.
local function utc_offset(epoch)
    return os.difftime(os.time(os.date("*t", epoch)), os.time(os.date("!*t", epoch)))
end

function ReadingState.iso_to_epoch(iso)
    if type(iso) ~= "string" then return nil end
    local y, mo, d, h, mi, s = iso:match("^(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)")
    if not y then return nil end
    local t = os.time({
        year = tonumber(y), month = tonumber(mo), day = tonumber(d),
        hour = tonumber(h), min = tonumber(mi), sec = tonumber(s),
    })
    return t + utc_offset(t)
end

function ReadingState.epoch_to_iso(epoch)
    return os.date("!%Y-%m-%dT%H:%M:%SZ", epoch)
end

-- KOReader summary.status -> Kobo StatusInfo.Status.
-- "abandoned" has no Kobo equivalent and is reported as still Reading.
local function status_to_kobo(status, percent)
    if status == "complete" then return "Finished" end
    if status == "reading" or status == "abandoned" then return "Reading" end
    if (percent or 0) > 0 then return "Reading" end
    return "ReadyToRead"
end

-- Kobo Status -> KOReader summary.status (nil means: leave unset).
local function status_from_kobo(status)
    if status == "Finished" then return "complete" end
    if status == "Reading" then return "reading" end
    return nil -- ReadyToRead or unknown
end

-- Builds the ReadingState object for PUT. The kepub Location from the server
-- cannot be mapped to KOReader positions, so it is echoed back untouched to
-- avoid breaking other Kobo clients; only ProgressPercent carries our data.
function ReadingState.to_kobo(uuid, local_state, server_state)
    local iso = ReadingState.epoch_to_iso(local_state.modified_time or os.time())
    local percent = math.floor((local_state.percent or 0) * 10000 + 0.5) / 100
    local bookmark = {
        LastModified = iso,
        ProgressPercent = percent,
        ContentSourceProgressPercent = percent,
    }
    local server_bookmark = server_state and server_state.CurrentBookmark
    if server_bookmark and server_bookmark.Location then
        bookmark.Location = server_bookmark.Location
    end
    return {
        EntitlementId = uuid,
        LastModified = iso,
        PriorityTimestamp = iso,
        StatusInfo = {
            LastModified = iso,
            Status = status_to_kobo(local_state.status, local_state.percent),
        },
        CurrentBookmark = bookmark,
        -- calibre-web requires the Statistics key to be present (KeyError
        -- -> HTTP 400 otherwise); we have no time stats, so send the bare
        -- minimum and let the server keep its own values.
        Statistics = {
            LastModified = iso,
        },
    }
end

-- Extracts what KOReader can represent from a server ReadingState.
function ReadingState.from_kobo(server_state)
    if type(server_state) ~= "table" then return nil end
    local bookmark = server_state.CurrentBookmark or {}
    local status_info = server_state.StatusInfo or {}
    return {
        percent = (bookmark.ProgressPercent or 0) / 100,
        status = status_from_kobo(status_info.Status),
        modified_time = ReadingState.iso_to_epoch(server_state.LastModified),
    }
end

-- Newest-wins conflict resolution.
-- Returns "push" (device newer), "pull" (server newer) or "noop".
function ReadingState.resolve(local_state, server_state)
    local local_time = local_state and local_state.modified_time
    local server_time = server_state
        and ReadingState.iso_to_epoch(server_state.LastModified)
    if not local_time and not server_time then return "noop" end
    if not server_time then return "push" end
    if not local_time then return "pull" end
    local diff = os.difftime(local_time, server_time)
    if diff > TOLERANCE_SECONDS then return "push" end
    if diff < -TOLERANCE_SECONDS then return "pull" end
    return "noop"
end

return ReadingState
