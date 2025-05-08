local bullets = {}
local config = require("modules.game.config")
local gameState = require("modules.game.gameState")

bullets.list = {}

function bullets.create(x, y, targetX, targetY)
    local dx = targetX - x
    local dy = targetY - y
    local len = math.sqrt(dx * dx + dy * dy)
    dx, dy = dx / len, dy / len
    
    table.insert(bullets.list, {
        x = x,
        y = y,
        dx = dx,
        dy = dy,
        angle = math.atan2(dy, dx),
        time = 0
    })
end

function bullets.update(dt, enemies)
    for i = #bullets.list, 1, -1 do
        local b = bullets.list[i]
        b.x = b.x + b.dx * config.bulletSpeed * dt
        b.y = b.y + b.dy * config.bulletSpeed * dt
        b.time = b.time + dt

        local bulletRemoved = false
        for j = #enemies, 1, -1 do
            local e = enemies[j]
            local dist = math.sqrt((b.x - e.x)^2 + (b.y - e.y)^2)
            if dist < e.size/2 + config.bulletWidth/2 then
                e.health = e.health - config.bulletDamage
                if e.health <= 0 then
                    gameState.increaseScore(e.type.score)
                    table.remove(enemies, j)
                end
                table.remove(bullets.list, i)
                bulletRemoved = true
                break
            end
        end

        if not bulletRemoved and (b.x < 0 or b.x > love.graphics.getWidth() or
           b.y < 0 or b.y > love.graphics.getHeight()) then
            table.remove(bullets.list, i)
        end
    end
end

function bullets.draw()
    love.graphics.setColor(config.bulletColor)
    for _, b in ipairs(bullets.list) do
        love.graphics.push()
        love.graphics.translate(b.x, b.y)
        local animAngle = b.angle + math.sin(b.time * 10) * 0.1
        love.graphics.rotate(animAngle)
        love.graphics.rectangle("fill", -config.bulletWidth / 2, -config.bulletHeight / 2, 
                              config.bulletWidth, config.bulletHeight)
        love.graphics.pop()
    end
end

function bullets.reset()
    bullets.list = {}
end

return bullets