local player = {}
local config = require("modules.game.config")
local bullets = require("modules.game.bullets")

-- Player state
player.x = math.ceil(config.gridSize / 2)
player.y = math.ceil(config.gridSize / 2) + 1
player.moveTimer = 0
player.health = config.playerMaxHealth
player.maxHealth = config.playerMaxHealth
player.invulnerabilityTimer = 0
player.lastDamageTime = 0
player.damageFlashTimer = 0

-- Power-up states
player.autoFireEnabled = false
player.autoFireTimer = 0
player.autoFireCooldown = 0.1

player.dashEnabled = false
player.dashDistance = 3
player.dashCooldown = 2
player.currentDashCooldown = 0

player.originalMoveCooldown = config.moveCooldown

function player.update(dt, gridSize, gridOffsetX, gridOffsetY)
    -- Handle dashboard cooldown if enabled
    if player.dashEnabled and player.currentDashCooldown > 0 then
        player.currentDashCooldown = player.currentDashCooldown - dt
    end
    
    -- Handle movement cooldown
    if player.moveTimer > 0 then
        player.moveTimer = player.moveTimer - dt
    else
        local moved = false
        
        -- Check for dash (spacebar)
        if player.dashEnabled and player.currentDashCooldown <= 0 and love.keyboard.isDown("space") then
            -- Determine dash direction based on the last movement key pressed
            local dashDir = {x = 0, y = 0}
            if love.keyboard.isDown("w") then dashDir.y = -1
            elseif love.keyboard.isDown("s") then dashDir.y = 1
            elseif love.keyboard.isDown("a") then dashDir.x = -1
            elseif love.keyboard.isDown("d") then dashDir.x = 1
            end
            
            -- Only dash if a direction is chosen
            if dashDir.x ~= 0 or dashDir.y ~= 0 then
                -- Calculate new position after dash
                local newX = player.x + dashDir.x * player.dashDistance
                local newY = player.y + dashDir.y * player.dashDistance
                
                -- Constrain to grid
                newX = math.max(1, math.min(gridSize, newX))
                newY = math.max(1, math.min(gridSize, newY))
                
                -- Apply dash
                player.x = newX
                player.y = newY
                player.currentDashCooldown = player.dashCooldown
                player.moveTimer = config.moveCooldown * 0.5  -- Half cooldown after dash
                moved = true
            end
        else
            -- Regular movement
            if love.keyboard.isDown("w") and player.y > 1 then 
                player.y = player.y - 1 
                moved = true
            elseif love.keyboard.isDown("s") and player.y < gridSize then 
                player.y = player.y + 1 
                moved = true
            elseif love.keyboard.isDown("a") and player.x > 1 then 
                player.x = player.x - 1 
                moved = true
            elseif love.keyboard.isDown("d") and player.x < gridSize then 
                player.x = player.x + 1 
                moved = true
            end
        end
        
        if moved then 
            player.moveTimer = config.moveCooldown 
        end
    end
    
    -- Handle invulnerability timer
    if player.invulnerabilityTimer > 0 then
        player.invulnerabilityTimer = player.invulnerabilityTimer - dt
    end
    
    -- Handle damage flash
    if player.damageFlashTimer > 0 then
        player.damageFlashTimer = player.damageFlashTimer - dt
    end
    
    -- Health regeneration when not recently damaged
    local timeSinceLastDamage = love.timer.getTime() - player.lastDamageTime
    if timeSinceLastDamage > 5 and player.health < player.maxHealth then
        player.health = math.min(player.maxHealth, player.health + config.playerHealthRegenRate * dt)
    end
end

function player.draw(gridOffsetX, gridOffsetY, fonts)
    local px = gridOffsetX + (player.x - 1) * config.cellSize + (config.cellSize - config.playerSize) / 2
    local py = gridOffsetY + (player.y - 1) * config.cellSize + (config.cellSize - config.playerSize) / 2
    
    -- Draw dash cooldown indicator if dash is enabled
    if player.dashEnabled then
        local dashReadyPercentage = 1 - (player.currentDashCooldown / player.dashCooldown)
        
        -- Draw dash cooldown ring
        local ringRadius = config.playerSize * 0.8
        love.graphics.setColor(0.2, 0.2, 0.2, 0.5)
        love.graphics.circle("line", px + config.playerSize/2, py + config.playerSize/2, ringRadius)
        
        if dashReadyPercentage < 1 then
            -- Draw cooldown arc (partial)
            love.graphics.setColor(0.4, 0.6, 1, 0.8)
            local segments = 32
            local startAngle = -math.pi/2
            local endAngle = startAngle + (math.pi * 2 * dashReadyPercentage)
            
            for i = 1, segments do
                local currAngle = startAngle + (i-1) * (endAngle - startAngle) / segments
                local nextAngle = startAngle + i * (endAngle - startAngle) / segments
                
                if nextAngle <= endAngle then
                    local x1 = px + config.playerSize/2 + math.cos(currAngle) * ringRadius
                    local y1 = py + config.playerSize/2 + math.sin(currAngle) * ringRadius
                    local x2 = px + config.playerSize/2 + math.cos(nextAngle) * ringRadius
                    local y2 = py + config.playerSize/2 + math.sin(nextAngle) * ringRadius
                    
                    love.graphics.line(x1, y1, x2, y2)
                end
            end
        else
            -- Dash is ready, show full circle
            love.graphics.setColor(0.4, 0.7, 1, 0.8)
            love.graphics.circle("line", px + config.playerSize/2, py + config.playerSize/2, ringRadius)
        end
    end
    
    -- Draw player with flashing effect if invulnerable
    if player.invulnerabilityTimer > 0 and math.floor(player.invulnerabilityTimer * 10) % 2 == 0 then
        love.graphics.setColor(1, 1, 1, 0.5)
    elseif player.damageFlashTimer > 0 then
        -- Flash red when damaged
        love.graphics.setColor(1, 0.3, 0.3, 1)
    else
        love.graphics.setColor(config.playerColor)
    end
    
    love.graphics.rectangle("fill", px, py, config.playerSize, config.playerSize)
    
    -- Draw health bar
    local healthBarWidth = config.playerSize
    local healthBarHeight = 5
    local healthPercentage = player.health / player.maxHealth
    
    -- Health bar background
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", px, py - 10, healthBarWidth, healthBarHeight)
    
    -- Health bar fill
    love.graphics.setColor(0.2, 0.8, 0.2, 1)
    love.graphics.rectangle("fill", px, py - 10, healthBarWidth * healthPercentage, healthBarHeight)
end

function player.reset()
    player.x = math.ceil(config.gridSize / 2)
    player.y = math.ceil(config.gridSize / 2) + 1
    player.moveTimer = 0
    player.health = player.maxHealth
    player.invulnerabilityTimer = 0
    player.lastDamageTime = 0
    player.damageFlashTimer = 0
    
    -- Reset power-up states
    player.autoFireEnabled = false
    player.autoFireTimer = 0
    player.dashEnabled = false
    player.currentDashCooldown = 0
    config.moveCooldown = player.originalMoveCooldown
end

function player.getScreenPosition(gridOffsetX, gridOffsetY)
    local px = gridOffsetX + (player.x - 1) * config.cellSize + config.cellSize / 2
    local py = gridOffsetY + (player.y - 1) * config.cellSize + config.cellSize / 2
    return px, py
end

function player.takeDamage(amount)
    -- Don't take damage if invulnerable
    if player.invulnerabilityTimer > 0 then
        return
    end
    
    -- Play hurt sound
    local sounds = require("modules.init").getSounds()
    if sounds and sounds.playerHurt then
        sounds.playerHurt:stop() -- Stop any currently playing instance
        sounds.playerHurt:play()
    end
    
    player.health = player.health - amount
    player.invulnerabilityTimer = config.playerDamageInvulnerabilityTime
    player.lastDamageTime = love.timer.getTime()
    player.damageFlashTimer = 0.2
    
    -- Check if player died
    if player.health <= 0 then
        -- Play death sound
        local sounds = require("modules.init").getSounds()
        if sounds and sounds.playerDeath then
            sounds.playerDeath:stop()
            sounds.playerDeath:play()
        end
        
        -- Trigger game over
        local gameState = require("modules.game.gameState")
        gameState.setGameOver(true)
        return true
    end
    
    return true
end

function player.getHealth()
    return player.health, player.maxHealth
end

return player