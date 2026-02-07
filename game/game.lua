local entityHandler = require("helpers.entity_handler")
local tick          = require("libraries.tick")
local keyboard      = require("helpers.keyboard")
local window        = require("helpers.window")

local level         = require("game.level")
local editorFactory = require("game.editor")

local game = {}

function game.load()
    window.load()

    game.player = level.build(entityHandler)

    game.editor = editorFactory.new(entityHandler, keyboard, window)
    game.editor:setPlayer(game.player)

    -- tuning
    game.maxDt = 0.1
    game.step  = 1 / 120
end

function game.update(dt)
    dt = math.min(dt, game.maxDt)

    while dt > 0 do
        local sdt = math.min(game.step, dt)
        dt = dt - sdt

        tick.update(sdt)
        entityHandler.update(sdt)
        game.editor:update(sdt)
    end
end

function game.draw()
    window.beginDraw()

    entityHandler.draw()
    game.editor:draw()

    window.endDraw()
end

function game.keypressed(key)
    -- Editor gets first dibs
    if game.editor:keypressed(key) then
        return
    end

    -- Player jump (only when not spawning)
    if game.player and not game.editor:isSpawnMode() and keyboard.keypressed(key, "jump") then
        game.player:queueJump()
    end
end

function game.mousepressed(x, y, button)
    game.editor:mousepressed(x, y, button)
end

function game.resize(w, h)
    window.resizeGame(w, h)
end

return game
