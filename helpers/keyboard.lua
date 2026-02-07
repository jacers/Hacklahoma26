local keyboard = {}

local input = {
    -- General movement
    up              = { "w", "up" },
    down            = { "s", "down" },
    left            = { "a", "left" },
    right           = { "d", "right" },

    -- Player movement
    jump            = { "space", "l" },
    run             = { "lshift", "rshift", "k" },

    -- Editor
    spawn_rectangle = { "q", "h" },
    spawn_sheep     = { "e", "j"},
}

-- Returns true while any key for the action is held
-- (for control and whatnot)
function keyboard.pressed(action)
    local keys = input[action]
    if not keys then return false end

    for _, key in ipairs(keys) do
        if love.keyboard.isDown(key) then
            return true
        end
    end
    return false
end

-- Returns true only on the frame the key is pressed
-- (for menus and UI)
function keyboard.keypressed(key, action)
    local keys = input[action]
    if not keys then return false end

    for _, k in ipairs(keys) do
        if key == k then
            return true
        end
    end
    return false
end

return keyboard
