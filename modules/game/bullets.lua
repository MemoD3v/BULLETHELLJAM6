local bullets = {}
local config = require("modules.game.config")
local gameState = require("modules.game.gameState")

bullets.list = {}
bullets.damageMultiplier = 1.0  -- Default multiplier, increased by Rapid Fire power-up

-- Create a new player bullet
function bullets.create(x, y, targetX, targetY)
    -- Debug info
    print("BULLET CREATE CALLED: from (" .. x .. "," .. y .. ") to (" .. targetX .. "," .. targetY .. ")")
    
    -- Fix for NaN direction vector
    if x == targetX and y == targetY then
        -- If mouse is clicked exactly on player, shoot upward
        targetY = y - 10
    end
    
    -- Play bullet sound
    local sounds = require("modules.init").getSounds()
    if sounds and sounds.playerShoot then
        sounds.playerShoot:stop() -- Stop any currently playing instance
        sounds.playerShoot:play()
    end
    
    -- Calculate direction with safeguards
    local dx = targetX - x
    local dy = targetY - y
    local length = math.sqrt(dx * dx + dy * dy)
    
    -- Prevent division by zero
    if length == 0 then length = 1 end
    
    local normalizedDx = dx / length
    local normalizedDy = dy / length
    
    -- Create the actual bullet
    local newBullet = {
        x = x,
        y = y,
        dx = normalizedDx,  -- Use normalized direction vector
        dy = normalizedDy,  -- Use normalized direction vector
        angle = math.atan2(dy, dx),
        time = 0
    }
    
    -- Insert the bullet into the list
    table.insert(bullets.list, newBullet)
    
    -- Debug confirmation
    print("Bullet created! Current bullet count: " .. #bullets.list)
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
                -- Apply damage multiplier (from Rapid Fire power-up)
                local damage = config.bulletDamage * bullets.damageMultiplier
                e.health = e.health - damage
                if e.health <= 0 then
                    -- Increase score and apply game mode multiplier
                    local gameModes = require("modules.game.gameModes")
                    local scoreMultiplier = gameModes.getScoreMultiplier()
                    gameState.increaseScore(e.type.score * scoreMultiplier)
                    
                    -- Apply vampiric effect if in Vampire mode
                    if gameModes.hasVampiricEffect() then
                        -- Heal the loading bar progress instead of the player
                        local loadingBar = require("modules.game.loadingBar")
                        local healAmount = gameModes.getHealthPerKill() / 100 -- Convert from health points to progress percentage
                        loadingBar.heal(healAmount)
                        
                        -- Visual feedback is handled in the loadingBar.heal function
                    end
                    
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