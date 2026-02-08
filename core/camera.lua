-- helpers/camera.lua
local camera     = {}

camera.x         = 0
camera.y         = 0

-- Zoom
camera.scale     = 2 -- Zoom (1 = normal)
camera.minScale  = 0.75
camera.maxScale  = 2.5

-- Follow behavior
camera.target    = nil
camera.smoothing = 12 -- higher = snappier

-- Bounds and viewport
camera.bounds    = nil -- { x, y, w, h }
camera.viewW     = nil
camera.viewH     = nil

-- Setup

function camera.setViewportSize(w, h)
    camera.viewW = w
    camera.viewH = h
end

function camera.setTarget(entity)
    camera.target = entity
end

function camera.setBounds(x, y, w, h)
    camera.bounds = { x = x, y = y, w = w, h = h }
end

function camera.setScale(s)
    camera.scale = math.max(camera.minScale, math.min(camera.maxScale, s))
end

function camera.zoomBy(amount)
    camera.setScale(camera.scale + amount)
end

-- Internals

local function clamp(v, a, b)
    if v < a then return a end
    if v > b then return b end
    return v
end

-- Update

function camera.update(dt)
    if not camera.target or not camera.viewW or not camera.viewH then
        return
    end

    -- Effective viewport size (accounts for zoom)
    local vw = camera.viewW / camera.scale
    local vh = camera.viewH / camera.scale

    -- Center on target
    local desiredX =
        (camera.target.x + (camera.target.width or 0) / 2) - vw / 2
    local desiredY =
        (camera.target.y + (camera.target.height or 0) / 2) - vh / 2

    -- Smooth follow
    local t = 1 - math.exp(-camera.smoothing * dt)
    camera.x = camera.x + (desiredX - camera.x) * t
    camera.y = camera.y + (desiredY - camera.y) * t

    -- Clamp to bounds
    if camera.bounds then
        local minX = camera.bounds.x
        local minY = camera.bounds.y
        local maxX = camera.bounds.x + camera.bounds.w - vw
        local maxY = camera.bounds.y + camera.bounds.h - vh
        camera.x = clamp(camera.x, minX, maxX)
        camera.y = clamp(camera.y, minY, maxY)
    end
end

-- Draw control

function camera.apply()
    love.graphics.push()
    love.graphics.scale(camera.scale, camera.scale)
    love.graphics.translate(
        -math.floor(camera.x),
        -math.floor(camera.y)
    )
end

function camera.clear()
    love.graphics.pop()
end

function camera.reset(x, y)
    camera.x = x or 0
    camera.y = y or 0
end

-- Utilities

-- For editor & mouse world positioning
function camera.getDrawOffset()
    return math.floor(camera.x), math.floor(camera.y)
end

-- Screen → world conversion (after window scaling)
function camera.screenToWorld(x, y)
    return
        x / camera.scale + camera.x,
        y / camera.scale + camera.y
end

return camera
