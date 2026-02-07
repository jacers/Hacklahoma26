local Rectangle = require("entities.rectangle")
local Player    = require("entities.player")

local level = {}

function level.build(entityHandler)
    -- Simple level
    entityHandler.spawn(Rectangle(40, 520, 900, 40))   -- ground
    entityHandler.spawn(Rectangle(220, 420, 220, 32))  -- platform
    entityHandler.spawn(Rectangle(520, 340, 220, 32))  -- platform
    entityHandler.spawn(Rectangle(740, 260, 180, 32))  -- platform

    local player = Player(80, 200)
    entityHandler.spawn(player)

    return player
end

return level
