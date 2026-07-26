-- Flattens an HTTP response into a string and back, for crossing a subprocess
-- pipe. Only a string can be written to the pipe, and the shape chosen is
-- HTTP's own -- status line, headers, blank line, body -- so this stays unaware
-- of which headers the caller cares about.
--
-- Pure logic: no KOReader dependencies.

local Wire = {}

-- A failed request has no response, so it is encoded as status 0 with the
-- message as the body; decode turns that back into nil plus the message.
function Wire.encode(resp, err)
    if not resp then
        return "0\n\n" .. tostring(err or "network error")
    end
    local lines = { tostring(resp.code) }
    for name, value in pairs(resp.headers or {}) do
        table.insert(lines, name .. ": " .. tostring(value))
    end
    table.insert(lines, "")
    table.insert(lines, resp.body or "")
    return table.concat(lines, "\n")
end

-- Header names are lowercased, matching what luasocket hands back, so callers
-- can look them up without worrying about the case the server used.
function Wire.decode(output)
    if type(output) ~= "string" then
        return nil, "no output from subprocess"
    end
    -- Non-greedy, so this splits on the first blank line; header values cannot
    -- contain one, and a body may.
    local head, body = output:match("^(.-)\n\n(.*)$")
    if not head then
        return nil, "malformed subprocess output"
    end
    local lines = {}
    for line in head:gmatch("[^\n]+") do
        table.insert(lines, line)
    end
    local code = tonumber(table.remove(lines, 1))
    if not code or code == 0 then
        return nil, body ~= "" and body or "network error"
    end
    local headers = {}
    for _idx, line in ipairs(lines) do
        local name, value = line:match("^(.-): (.*)$")
        if name then
            headers[name:lower()] = value
        end
    end
    return { code = code, headers = headers, body = body }
end

return Wire
