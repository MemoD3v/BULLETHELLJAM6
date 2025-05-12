local enemyBullets = {}
local config = require("modules.game.config")
local player = require("modules.game.player")

enemyBullets.list = {}

-- Create a new bullet from an enemy
function enemyBullets.create(enemyX, enemyY, enemyType, gridOffsetX, gridOffsetY)
    -- Get player position for targeting
    local playerScreenX, playerScreenY = player.getScreenPosition(gridOffsetX, gridOffsetY)
    
    -- Calculate direction to player
    local dx = playerScreenX - enemyX
    local dy = playerScreenY - enemyY
    local len = math.sqrt(dx * dx + dy * dy)
    dx, dy = dx / len, dy / len
    
    -- Add some randomization to aiming based on enemy type (higher tier enemies are more accurate)
    local accuracyFactor = 1 - (0.3 / (enemyType.tier or 1))
    local randomAngle = (math.random() * 2 - 1) * (1 - accuracyFactor) * 0.5
    local rotatedDx = dx * math.cos(randomAngle) - dy * math.sin(randomAngle)
    local rotatedDy = dx * math.sin(randomAngle) + dy * math.cos(randomAngle)
    
    -- Create the bullet
    table.insert(enemyBullets.list, {
        x = enemyX,
        y = enemyY,
        dx = rotatedDx,
        dy = rotatedDy,
        angle = math.atan2(rotatedDy, rotatedDx),
        time = 0,
        speed = enemyType.bulletSpeed or config.enemyBulletSpeed,
        color = enemyType.bulletColor or {1, 0.2, 0.2},
        size = enemyType.bulletSize or 6,
        damage = enemyType.damage or 10
    })
end

function enemyBullets.update(dt, gridOffsetX, gridOffsetY)
    for i = #enemyBullets.list, 1, -1 do
        local b = enemyBullets.list[i]
        b.x = b.x + b.dx * b.speed * dt
        b.y = b.y + b.dy * b.speed * dt
        b.time = b.time + dt
        
        -- Check collision with player
        local playerScreenX, playerScreenY = player.getScreenPosition(gridOffsetX, gridOffsetY)
        local dist = math.sqrt((b.x - playerScreenX)^2 + (b.y - playerScreenY)^2)
        if dist < config.playerSize/2 + b.size/2 then
            -- Player is hit
            player.takeDamage(b.damage)
            table.remove(enemyBullets.list, i)
        elseif b.x < -50 or b.x > love.graphics.getWidth() + 50 or
               b.y < -50 or b.y > love.graphics.getHeight() + 50 then
            -- Bullet is off-screen
            table.remove(enemyBullets.list, i)
        end
    end
end

function enemyBullets.draw(gridOffsetX, gridOffsetY)
    -- Parameters are not directly used in this function but are now accepted
    -- to match how this function is called in enemies.draw
    
    for _, b in ipairs(enemyBullets.list) do
        love.graphics.push()
        love.graphics.translate(b.x, b.y)
        local animAngle = b.angle + math.sin(b.time * 10) * 0.1
        love.graphics.rotate(animAngle)
        
        -- Draw enemy bullet with pulsating effect
        local pulseScale = 0.8 + 0.2 * math.sin(b.time * 8)
        love.graphics.setColor(b.color)
        love.graphics.circle("fill", 0, 0, b.size * pulseScale)
        
        -- Add glow effect
        love.graphics.setColor(b.color[1], b.color[2], b.color[3], 0.3)
        love.graphics.circle("fill", 0, 0, b.size * 1.5 * pulseScale)
        
        love.graphics.pop()
    end
end

function enemyBullets.reset()
    enemyBullets.list = {}
end

return enemyBullets
