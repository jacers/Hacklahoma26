-- Vibd coded JSON decoder (supports objects, arrays, strings, numbers, true/false/null)
-- Not a full serializer; decode-only.

local json = {}

local function decode_error(str, idx, msg)
    error(("JSON decode error at char %d: %s"):format(idx, msg), 2)
end

local function skip_ws(str, i)
    while true do
        local c = str:sub(i, i)
        if c == " " or c == "\n" or c == "\r" or c == "\t" then
            i = i + 1
        else
            return i
        end
    end
end

local function parse_string(str, i)
    -- assumes current char is "
    i = i + 1
    local out = {}
    local n = 1

    while true do
        local c = str:sub(i, i)
        if c == "" then
            decode_error(str, i, "unterminated string")
        elseif c == "\"" then
            return table.concat(out), i + 1
        elseif c == "\\" then
            local esc = str:sub(i + 1, i + 1)
            if esc == "\"" or esc == "\\" or esc == "/" then
                out[n] = esc; n = n + 1; i = i + 2
            elseif esc == "b" then
                out[n] = "\b"; n = n + 1; i = i + 2
            elseif esc == "f" then
                out[n] = "\f"; n = n + 1; i = i + 2
            elseif esc == "n" then
                out[n] = "\n"; n = n + 1; i = i + 2
            elseif esc == "r" then
                out[n] = "\r"; n = n + 1; i = i + 2
            elseif esc == "t" then
                out[n] = "\t"; n = n + 1; i = i + 2
            elseif esc == "u" then
                local hex = str:sub(i + 2, i + 5)
                if not hex:match("^[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]$") then
                    decode_error(str, i, "invalid unicode escape")
                end
                local code = tonumber(hex, 16)
                -- Basic BMP handling; enough for most Tiled JSON usage
                if code <= 0x7F then
                    out[n] = string.char(code)
                elseif code <= 0x7FF then
                    out[n] = string.char(
                        0xC0 + math.floor(code / 0x40),
                        0x80 + (code % 0x40)
                    )
                else
                    out[n] = string.char(
                        0xE0 + math.floor(code / 0x1000),
                        0x80 + (math.floor(code / 0x40) % 0x40),
                        0x80 + (code % 0x40)
                    )
                end
                n = n + 1
                i = i + 6
            else
                decode_error(str, i, "invalid escape: \\" .. esc)
            end
        else
            out[n] = c
            n = n + 1
            i = i + 1
        end
    end
end

local function parse_number(str, i)
    local s = i
    local c = str:sub(i, i)
    if c == "-" then i = i + 1 end

    local d = str:sub(i, i)
    if d == "0" then
        i = i + 1
    else
        if not d:match("%d") then
            decode_error(str, i, "invalid number")
        end
        while str:sub(i, i):match("%d") do i = i + 1 end
    end

    if str:sub(i, i) == "." then
        i = i + 1
        if not str:sub(i, i):match("%d") then
            decode_error(str, i, "invalid number fraction")
        end
        while str:sub(i, i):match("%d") do i = i + 1 end
    end

    local e = str:sub(i, i)
    if e == "e" or e == "E" then
        i = i + 1
        local sign = str:sub(i, i)
        if sign == "+" or sign == "-" then i = i + 1 end
        if not str:sub(i, i):match("%d") then
            decode_error(str, i, "invalid exponent")
        end
        while str:sub(i, i):match("%d") do i = i + 1 end
    end

    local num = tonumber(str:sub(s, i - 1))
    return num, i
end

local parse_value

local function parse_array(str, i)
    -- assumes current char is [
    i = i + 1
    local arr = {}
    local n = 1

    i = skip_ws(str, i)
    if str:sub(i, i) == "]" then
        return arr, i + 1
    end

    while true do
        local v
        v, i = parse_value(str, i)
        arr[n] = v
        n = n + 1

        i = skip_ws(str, i)
        local c = str:sub(i, i)
        if c == "," then
            i = skip_ws(str, i + 1)
        elseif c == "]" then
            return arr, i + 1
        else
            decode_error(str, i, "expected ',' or ']'")
        end
    end
end

local function parse_object(str, i)
    -- assumes current char is {
    i = i + 1
    local obj = {}

    i = skip_ws(str, i)
    if str:sub(i, i) == "}" then
        return obj, i + 1
    end

    while true do
        if str:sub(i, i) ~= "\"" then
            decode_error(str, i, "expected string key")
        end

        local key
        key, i = parse_string(str, i)

        i = skip_ws(str, i)
        if str:sub(i, i) ~= ":" then
            decode_error(str, i, "expected ':'")
        end
        i = skip_ws(str, i + 1)

        local val
        val, i = parse_value(str, i)
        obj[key] = val

        i = skip_ws(str, i)
        local c = str:sub(i, i)
        if c == "," then
            i = skip_ws(str, i + 1)
        elseif c == "}" then
            return obj, i + 1
        else
            decode_error(str, i, "expected ',' or '}'")
        end
    end
end

parse_value = function(str, i)
    i = skip_ws(str, i)
    local c = str:sub(i, i)

    if c == "\"" then
        return parse_string(str, i)
    elseif c == "{" then
        return parse_object(str, i)
    elseif c == "[" then
        return parse_array(str, i)
    elseif c == "-" or c:match("%d") then
        return parse_number(str, i)
    elseif str:sub(i, i + 3) == "true" then
        return true, i + 4
    elseif str:sub(i, i + 4) == "false" then
        return false, i + 5
    elseif str:sub(i, i + 3) == "null" then
        return nil, i + 4
    end

    decode_error(str, i, "unexpected character '" .. c .. "'")
end

function json.decode(str)
    if type(str) ~= "string" then
        error("json.decode expects a string", 2)
    end
    local val, i = parse_value(str, 1)
    i = skip_ws(str, i)
    if i <= #str then
        decode_error(str, i, "trailing garbage")
    end
    return val
end

return json
