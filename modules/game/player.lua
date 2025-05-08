local player = {}
local config = require("modules.game.config")

-- Player state
player.x = math.ceil(config.gridSize / 2)
player.y = math.ceil(config.gridSize / 2) + 1
player.moveTimer = 0
player.health = config.playerMaxHealth
player.maxHealth = config.playerMaxHealth
player.invulnerabilityTimer = 0
player.lastDamageTime = 0
player.damageFlashTimer = 0

function player.update(dt, gridSize)
    -- Handle movement cooldown
    if player.moveTimer > 0 then
        player.moveTimer = player.moveTimer - dt
    else
        local moved = false
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

function player.draw(gridOffsetX, gridOffsetY)
    local px = gridOffsetX + (player.x - 1) * config.cellSize + (config.cellSize - config.playerSize) / 2
    local py = gridOffsetY + (player.y - 1) * config.cellSize + (config.cellSize - config.playerSize) / 2
    
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
end

function player.getScreenPosition(gridOffsetX, gridOffsetY)
    local px = gridOffsetX + (player.x - 1) * config.cellSize + config.cellSize / 2
    local py = gridOffsetY + (player.y - 1) * config.cellSize + config.cellSize / 2
    return px, py
end

function player.takeDamage(amount)
    -- Don't take damage if invulnerable
    if player.invulnerabilityTimer > 0 then
        return false
    end
    
    -- Apply damage
    player.health = math.max(0, player.health - amount)
    player.invulnerabilityTimer = config.playerDamageInvulnerabilityTime
    player.lastDamageTime = love.timer.getTime()
    player.damageFlashTimer = 0.2
    
    -- Check if player died
    if player.health <= 0 then
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