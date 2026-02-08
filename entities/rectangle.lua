-- entities/rectangle.lua
local BaseEntity = require("entities.entity")

local Rectangle = BaseEntity:extend()

function Rectangle:new(x, y, w, h)
    BaseEntity.new(self, "Rectangle", x, y)
    self.width  = w or 16
    self.height = h or 16
    self.solid  = self.solid or false
end

function Rectangle:draw()
    -- visible fill + outline so you can’t miss it
    love.graphics.setColor(1, 1, 1, 0.25)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)

    love.graphics.setColor(1, 1, 1, 1)
end

return function(x, y, w, h)
    return Rectangle(x, y, w, h)
end
