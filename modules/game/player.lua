local player = {}
local config = require("modules.game.config")
local bullets = require("modules.game.bullets")

local playerSprite = love.graphics.newImage("source/sprites/player.png")

-- Player state
player.x = 4
player.y = 4
player.health = config.playerMaxHealth
player.maxHealth = config.playerMaxHealth -- Initialize maxHealth to fix nil error
player.invulnerabilityTimer = 0
player.lastDamageTime = 0
player.damageFlashTimer = 0 -- Initialize damageFlashTimer to fix nil error
player.score = 0

-- Auto-fire power-up
player.autoFireEnabled = false
player.autoFireCooldown = 0
player.autoFireTimer = 0

-- Movement and dash
player.moveCooldownTimer = 0
player.moveTimer = 0 -- Initialize moveTimer to fix the nil comparison error
player.dashEnabled = false
player.dashCooldown = 0
player.currentDashCooldown = 0
player.isDashing = false
player.dashDirection = nil
player.dashProgress = 0
player.dashDuration = 0.15 -- Seconds to complete a dash

-- RogueLike mode variables
player.moveSpeed = 200 -- Pixels per second for continuous movement
player.realX = 0      -- Exact X position for continuous movement
player.realY = 0      -- Exact Y position for continuous movement

-- Shield power-up
player.shieldEnabled = false

-- Nuke power-up
player.nukeEnabled = false
player.nukeUsed = false
player.nukeEffectTime = 0

-- Passive nuke ability
player.passiveNukeCharge = 0
player.passiveNukeMaxCharge = 10 -- 10 seconds to fully charge
player.passiveNukeReady = false
player.passiveNukeRadius = 300 -- Visual radius for explosion effect
player.passiveNukeEffectTime = 0 -- Animation timer
player.passiveNukeUnlocked = false -- Locked until first checkpoint
player.nukeUnlockMessageTimer = 0 -- Timer for unlock message display

-- Rapid fire power-up
player.fireRateMultiplier = 1.0 -- Default is no multiplier

function player.update(dt, gridSize, gridOffsetX, gridOffsetY)
    -- Update nuke effect timer if active
    if player.nukeEffectTime and player.nukeEffectTime > 0 then
        player.nukeEffectTime = player.nukeEffectTime - dt
    end
    
    -- Passive nuke unlock message timer
    if player.nukeUnlockMessageTimer > 0 then
        player.nukeUnlockMessageTimer = player.nukeUnlockMessageTimer - dt
    end
    
    -- Only charge the nuke if it's unlocked
    if player.passiveNukeUnlocked and not player.passiveNukeReady then
        player.passiveNukeCharge = player.passiveNukeCharge + dt
        if player.passiveNukeCharge >= player.passiveNukeMaxCharge then
            player.passiveNukeCharge = player.passiveNukeMaxCharge
            player.passiveNukeReady = true
            
            -- Play sound effect when nuke is ready
            local sounds = require("modules.init").getSounds()
            if sounds and sounds.powerUp then
                sounds.powerUp:stop()
                sounds.powerUp:play()
            end
        end
    end
    
    -- Update passive nuke effect animation
    if player.passiveNukeEffectTime > 0 then
        player.passiveNukeEffectTime = player.passiveNukeEffectTime - dt
        
        -- During the nuke effect, we check for enemies to destroy (continuous effect)
        if player.passiveNukeEffectTime > 0.5 then  -- Only in the first half of the effect
            local enemies = require("modules.game.enemies")
            local enemyBullets = require("modules.game.enemyBullets")
            
            -- Clear enemy bullets as part of the ongoing effect
            if enemyBullets and enemyBullets.list then
                enemyBullets.list = {}
            end
            
            -- Continuously damage enemies within the nuke radius
            if enemies and enemies.list then
                for i = #enemies.list, 1, -1 do
                    enemies.list[i].health = 0
                end
            end
        end
    end
    
    -- Handle dashboard cooldown if enabled
    if player.dashEnabled and player.currentDashCooldown > 0 then
        player.currentDashCooldown = player.currentDashCooldown - dt
    end
    
    -- Get game mode for movement type
    local gameModes = require("modules.game.gameModes")
    local isRogueMode = gameModes.isRogueLike()
    
    if isRogueMode then
        -- ROGUELIKE MODE: Continuous movement
        -- Initialize realX and realY if not set yet
        if player.realX == 0 then
            player.realX = gridOffsetX + (player.x - 0.5) * config.cellSize
            player.realY = gridOffsetY + (player.y - 0.5) * config.cellSize
        end
        
        -- Calculate movement direction
        local dx, dy = 0, 0
        if love.keyboard.isDown("w") then dy = dy - 1 end
        if love.keyboard.isDown("s") then dy = dy + 1 end
        if love.keyboard.isDown("a") then dx = dx - 1 end
        if love.keyboard.isDown("d") then dx = dx + 1 end
        
        -- Normalize diagonal movement
        if dx ~= 0 and dy ~= 0 then
            local len = math.sqrt(dx * dx + dy * dy)
            dx, dy = dx / len, dy / len
        end
        
        -- Apply movement
        if dx ~= 0 or dy ~= 0 then
            player.realX = player.realX + dx * player.moveSpeed * dt
            player.realY = player.realY + dy * player.moveSpeed * dt
            
            -- Add boundaries to prevent moving outside the play area - 50% larger for RogueLike mode
            local expansionFactor = 1.5 -- Make play area 50% larger than the grid
            local origGridSize = gridSize * config.cellSize 
            local expandedGridSize = origGridSize * expansionFactor
            local expansionAmount = (expandedGridSize - origGridSize) / 2
            
            -- Calculate the expanded boundaries
            local minX = gridOffsetX - expansionAmount
            local minY = gridOffsetY - expansionAmount
            local maxX = gridOffsetX + origGridSize + expansionAmount
            local maxY = gridOffsetY + origGridSize + expansionAmount
            
            player.realX = math.max(minX, math.min(maxX, player.realX))
            player.realY = math.max(minY, math.min(maxY, player.realY))
            
            -- Update grid position for compatibility with non-roguelike code
            player.x = math.floor((player.realX - gridOffsetX) / config.cellSize) + 1
            player.y = math.floor((player.realY - gridOffsetY) / config.cellSize) + 1
        end
        
        -- Handle dashing in roguelike mode
        if player.dashEnabled and player.currentDashCooldown <= 0 and love.keyboard.isDown("space") and (dx ~= 0 or dy ~= 0) then
            -- Apply dash in the current movement direction
            player.realX = player.realX + dx * player.moveSpeed * 5 * dt
            player.realY = player.realY + dy * player.moveSpeed * 5 * dt
            
            -- Apply the same expanded boundaries
            local expansionFactor = 1.5 -- Make play area 50% larger than the grid
            local origGridSize = gridSize * config.cellSize 
            local expandedGridSize = origGridSize * expansionFactor
            local expansionAmount = (expandedGridSize - origGridSize) / 2
            
            -- Calculate the expanded boundaries
            local minX = gridOffsetX - expansionAmount
            local minY = gridOffsetY - expansionAmount
            local maxX = gridOffsetX + origGridSize + expansionAmount
            local maxY = gridOffsetY + origGridSize + expansionAmount
            
            player.realX = math.max(minX, math.min(maxX, player.realX))
            player.realY = math.max(minY, math.min(maxY, player.realY))
            
            -- Update grid position
            player.x = math.floor((player.realX - gridOffsetX) / config.cellSize) + 1
            player.y = math.floor((player.realY - gridOffsetY) / config.cellSize) + 1
            
            player.currentDashCooldown = player.dashCooldown
        end
    else
        -- ORIGINAL MODE: Grid-based movement
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
    local px, py
    local gameModes = require("modules.game.gameModes")
    
    if gameModes.isRogueLike() and player.realX ~= 0 then
        px = player.realX - config.playerSize / 2
        py = player.realY - config.playerSize / 2
    else
        px = gridOffsetX + (player.x - 1) * config.cellSize + (config.cellSize - config.playerSize) / 2
        py = gridOffsetY + (player.y - 1) * config.cellSize + (config.cellSize - config.playerSize) / 2
    end

    -- Passive nuke effect
    if player.passiveNukeEffectTime > 0 then
        local effectProgress = 1 - (player.passiveNukeEffectTime / 1.0)
        local maxRadius = player.passiveNukeRadius
        local currentRadius = maxRadius * effectProgress
        local alpha = 0.8 - effectProgress * 0.8
        love.graphics.setColor(1, 0.4, 0.1, alpha)
        love.graphics.circle("fill", px + config.playerSize/2, py + config.playerSize/2, currentRadius)
        love.graphics.setColor(1, 0.8, 0.2, alpha * 1.5)
        love.graphics.circle("line", px + config.playerSize/2, py + config.playerSize/2, currentRadius * 0.9)
        love.graphics.circle("line", px + config.playerSize/2, py + config.playerSize/2, currentRadius * 0.8)
    end

    -- Shield effect
    if player.shieldEnabled then
        local shieldSize = config.playerSize * 1.5
        local shieldX = px + config.playerSize/2 - shieldSize/2
        local shieldY = py + config.playerSize/2 - shieldSize/2
        local pulseAmount = 0.2 + math.sin(love.timer.getTime() * 5) * 0.1
        love.graphics.setColor(0.3, 0.8, 0.9, pulseAmount + 0.2)
        love.graphics.circle("line", px + config.playerSize/2, py + config.playerSize/2, shieldSize/2 + 2)
        love.graphics.setColor(0.3, 0.8, 0.9, pulseAmount * 0.5)
        love.graphics.circle("fill", px + config.playerSize/2, py + config.playerSize/2, shieldSize/2)
    end

    -- Dash cooldown indicator
    if player.dashEnabled then
        local dashReadyPercentage = 1 - (player.currentDashCooldown / player.dashCooldown)
        local ringRadius = config.playerSize * 0.8
        love.graphics.setColor(0.2, 0.2, 0.2, 0.5)
        love.graphics.circle("line", px + config.playerSize/2, py + config.playerSize/2, ringRadius)

        if dashReadyPercentage < 1 then
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
            love.graphics.setColor(0.4, 0.7, 1, 0.8)
            love.graphics.circle("line", px + config.playerSize/2, py + config.playerSize/2, ringRadius)
        end
    end

    -- Set color based on state
    if player.invulnerabilityTimer > 0 and math.floor(player.invulnerabilityTimer * 10) % 2 == 0 then
        love.graphics.setColor(1, 1, 1, 0.5)
    elseif player.damageFlashTimer > 0 then
        love.graphics.setColor(1, 0.3, 0.3, 1)
    else
        love.graphics.setColor(1, 1, 1, 1) -- White for full sprite color
    end

    -- Draw player sprite
    local sprite = player.sprite or love.graphics.newImage("source/sprites/player.png")
    local spriteW, spriteH = sprite:getDimensions()
    local scale = config.playerSize / math.max(spriteW, spriteH)
    local offsetX = (config.playerSize - spriteW * scale) / 2
    local offsetY = (config.playerSize - spriteH * scale) / 2
    love.graphics.draw(sprite, px + offsetX, py + offsetY, 0, scale, scale)

    -- Nuke explosion effect
    if player.nukeEffectTime and player.nukeEffectTime > 0 then
        local effectProgress = 1 - (player.nukeEffectTime / 0.5)
        local maxRadius = 800
        local currentRadius = maxRadius * effectProgress
        local alpha = 0.8 - effectProgress * 0.8
        love.graphics.setColor(1, 0.4, 0.1, alpha)
        love.graphics.circle("fill", px + config.playerSize/2, py + config.playerSize/2, currentRadius)
        love.graphics.setColor(1, 0.8, 0.2, alpha * 1.5)
        love.graphics.circle("line", px + config.playerSize/2, py + config.playerSize/2, currentRadius * 0.9)
        love.graphics.circle("line", px + config.playerSize/2, py + config.playerSize/2, currentRadius * 0.8)
    end

    -- Health bar
    local healthBarWidth = config.playerSize
    local healthBarHeight = 5
    local healthPercentage = player.health / player.maxHealth
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", px, py - 10, healthBarWidth, healthBarHeight)
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
    
    -- Reset RogueLike mode variables
    player.realX = 0 -- Will be reinitialized during the first update
    player.realY = 0
    
    -- Reset passive nuke
    player.passiveNukeCharge = 0
    player.passiveNukeReady = false
    player.passiveNukeEffectTime = 0
    player.passiveNukeUnlocked = false
    player.nukeUnlockMessageTimer = 0
    
    -- Reset power-up states
    player.autoFireEnabled = false
    player.autoFireTimer = 0
    player.dashEnabled = false
    player.currentDashCooldown = 0
    player.shieldEnabled = false
    player.nukeEnabled = false
    player.nukeUsed = false
    player.nukeEffectTime = 0
    player.fireRateMultiplier = 1.0
end

function player.getScreenPosition(gridOffsetX, gridOffsetY)
    -- Provide default values for grid offsets if they're nil
    gridOffsetX = gridOffsetX or 0
    gridOffsetY = gridOffsetY or 0
    
    local px = gridOffsetX + (player.x - 1) * config.cellSize + config.cellSize / 2
    local py = gridOffsetY + (player.y - 1) * config.cellSize + config.cellSize / 2
    return px, py
end

-- Set the player's maximum health
function player.setMaxHealth(value)
    player.maxHealth = value
end

-- Set the player's current health
function player.setHealth(value)
    player.health = value
end

-- Handle key press for nuke and dash abilities
function player.keypressed(key, enemiesList)
    -- Handle dash
    if player.dashEnabled and key == "space" and player.currentDashCooldown <= 0 and not player.isDashing then
        -- We'll keep using the existing dash logic if present
    end
    
    -- Handle passive nuke ability with Q key
    if key == "q" and player.passiveNukeUnlocked and player.passiveNukeReady then
        print("Nuke activated!") -- Debug message
        
        -- Reset nuke for recharging
        player.passiveNukeReady = false
        player.passiveNukeCharge = 0
        player.passiveNukeEffectTime = 1.0 -- Duration of visual effect in seconds
        
        -- Set up a safe reference to enemies list that we'll use
        local enemies = require("modules.game.enemies")
        local enemyBullets = require("modules.game.enemyBullets")
        local bullets = require("modules.game.bullets")
                
        -- Clear all enemy bullets from the screen
        if enemyBullets and enemyBullets.list then
            print("Clearing enemy bullets: " .. #enemyBullets.list)
            enemyBullets.list = {}
        end
        
        -- Clear all regular bullets from the screen
        if bullets and bullets.list then
            print("Clearing player bullets: " .. #bullets.list)
            bullets.list = {}
        end
        
        -- DIRECTLY remove all enemies from the list instead of setting health to 0
        if enemies and enemies.list then
            print("Removing enemies: " .. #enemies.list)
            -- Track how many enemies we had to give score/progress
            local enemyCount = #enemies.list
            -- Give score and progress for each enemy removed
            if enemyCount > 0 then
                -- Increment the score using the correct function
                local gameState = require("modules.game.gameState")
                local engine = require("modules.game.engine")
                
                -- Add score for each enemy removed
                gameState.increaseScore(enemyCount * 100)
                
                -- Log the score increase
                print("Nuke cleared " .. enemyCount .. " enemies, adding " .. (enemyCount * 100) .. " points")
                
                -- Increment the engine's enemy counter (if needed)
                for i = 1, enemyCount do
                    engine.incrementEnemies()
                end
            end
            
            -- Clear the enemy list completely
            enemies.list = {}
        end
        
        -- Play explosion sound effect
        local sounds = require("modules.init").getSounds()
        if sounds and sounds.explosion then
            sounds.explosion:stop()
            sounds.explosion:play()
        elseif sounds and sounds.playerShoot then
            sounds.playerShoot:stop()
            sounds.playerShoot:play()
        end
        
        -- Camera shake effect
        local camera = require("modules.game.camera")
        camera.shake(8, 1.0) -- Strong shake for explosion
    end
    
    -- Handle nuke power-up from original code (kept for compatibility)
    if player.nukeEnabled and key == "space" and not player.nukeUsed then
        player.nukeUsed = true
        
        -- Clear all enemy bullets
        if bullets.enemyBullets then
            bullets.enemyBullets = {}
        end
        
        -- Clear all regular bullets from the screen
        bullets.list = {}
        
        -- Damage all enemies on screen
        if enemiesList then
            for i = #enemiesList, 1, -1 do
                enemiesList[i].health = 0  -- Kill the enemy
            end
        end
        
        -- Play explosion sound effect
        local sounds = require("modules.init").getSounds()
        if sounds and sounds.playerShoot then
            sounds.playerShoot:stop()
            sounds.playerShoot:play()
        end
        
        -- Create visual effect (will be handled in main draw loop)
        player.nukeEffectTime = 0.5  -- Duration of visual effect in seconds
    end
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

-- Heal the player by the specified amount
function player.heal(amount)
    -- Only heal if player is alive
    if player.health <= 0 then return false end
    
    local oldHealth = player.health
    player.health = math.min(player.maxHealth, player.health + amount)
    
    -- Play healing sound if health increased
    if player.health > oldHealth then
        -- Visual effect for healing could be added here
        return true
    end
    
    return false
end

return player