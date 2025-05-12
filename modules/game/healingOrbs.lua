local healingOrbs = {}
local config = require("modules.game.config")
local player = require("modules.game.player")

-- Store active healing orbs
healingOrbs.list = {}

-- Configuration
healingOrbs.spawnInterval = 5         -- Base time between orb spawns in seconds (reduced from 10)
healingOrbs.spawnRandomness = 3       -- Random time added to spawn interval in seconds (reduced from 5)
healingOrbs.lastSpawnTime = 0         -- Time since last orb spawn
healingOrbs.nextSpawnTime = 0         -- When the next orb will spawn
healingOrbs.healAmount = 999999       -- Effectively heal to full health
healingOrbs.size = 15                 -- Size of the orb in pixels
healingOrbs.pulseSpeed = 2            -- How fast the orb pulses
healingOrbs.glowRadius = 25           -- Radius of the glow effect

-- Initialize the healing orbs system
function healingOrbs.init()
    healingOrbs.list = {}
    healingOrbs.lastSpawnTime = 0
    healingOrbs.setNextSpawnTime() -- Set the next spawn time immediately
    
    -- Force an orb to spawn soon after game start for testing
    healingOrbs.lastSpawnTime = healingOrbs.nextSpawnTime - 1
end

-- Set the time for the next orb spawn
function healingOrbs.setNextSpawnTime()
    -- Use a fixed value first if love.math isn't available yet
    local randomTime = 0
    if love and love.math then
        randomTime = love.math.random() * healingOrbs.spawnRandomness
    end
    healingOrbs.nextSpawnTime = healingOrbs.spawnInterval + randomTime
end

-- Spawn a healing orb at a random position in the grid
function healingOrbs.spawnOrb(gridOffsetX, gridOffsetY)
    local gridSize = config.gridSize
    local cellSize = config.cellSize
    
    -- Find a safe position away from the player and engine
    local x, y
    local tooClose = true
    local attempts = 0
    
    while tooClose and attempts < 20 do
        x = love.math.random(2, gridSize - 1)
        y = love.math.random(2, gridSize - 1)
        
        -- Check if this position is far enough from player and engine
        local engine = require("modules.game.engine")
        local playerPosX, playerPosY = player.x, player.y
        local engX, engY = engine.x, engine.y
        
        local distToPlayer = math.sqrt((x - playerPosX)^2 + (y - playerPosY)^2)
        local distToEngine = math.sqrt((x - engX)^2 + (y - engY)^2)
        
        -- Ensure orbs don't spawn right on top of player or engine
        if distToPlayer > 3 and distToEngine > 2 then
            tooClose = false
        end
        
        attempts = attempts + 1
    end
    
    -- If we couldn't find a good position after 20 attempts, use a fallback
    if tooClose then
        x = love.math.random(2, gridSize - 1)
        y = love.math.random(2, gridSize - 1)
    end
    
    -- Convert grid position to screen coordinates
    local screenX = gridOffsetX + (x - 0.5) * cellSize
    local screenY = gridOffsetY + (y - 0.5) * cellSize
    
    -- Create new orb with animation data
    local newOrb = {
        x = x,
        y = y,
        screenX = screenX,
        screenY = screenY,
        animTimer = love.math.random() * 10, -- Random start time for animation variety
        pulseScale = 1,
        rotationAngle = 0,
        spawnEffectTime = 1.0, -- Spawn effect duration in seconds
        glowAlpha = 0
    }
    
    -- Add to orbs list
    table.insert(healingOrbs.list, newOrb)
    
    -- Play spawn sound
    local sounds = require("modules.init").getSounds()
    if sounds and sounds.powerUpSpawn then
        sounds.powerUpSpawn:play()
    end
    
    return newOrb
end

-- Update all healing orbs
function healingOrbs.update(dt, gridOffsetX, gridOffsetY)
    -- Check if it's time to spawn a new orb
    healingOrbs.lastSpawnTime = healingOrbs.lastSpawnTime + dt
    if healingOrbs.lastSpawnTime >= healingOrbs.nextSpawnTime then
        healingOrbs.spawnOrb(gridOffsetX, gridOffsetY)
        healingOrbs.lastSpawnTime = 0
        healingOrbs.setNextSpawnTime()
    end
    
    -- Update existing orbs
    for i, orb in ipairs(healingOrbs.list) do
        -- Update animation
        orb.animTimer = orb.animTimer + dt
        orb.pulseScale = 1 + 0.2 * math.sin(orb.animTimer * healingOrbs.pulseSpeed)
        orb.rotationAngle = orb.animTimer * 0.5
        
        if orb.spawnEffectTime > 0 then
            orb.spawnEffectTime = orb.spawnEffectTime - dt
            orb.glowAlpha = 1 - orb.spawnEffectTime
        else
            orb.glowAlpha = 0.5 + 0.3 * math.sin(orb.animTimer * 2)
        end
        
        -- Update screen position (in case the grid offset changed)
        orb.screenX = gridOffsetX + (orb.x - 0.5) * config.cellSize
        orb.screenY = gridOffsetY + (orb.y - 0.5) * config.cellSize
        
        -- Check for player collision in grid mode
        local px, py = player.x, player.y
        local gameModes = require("modules.game.gameModes")
        
        if gameModes.isRogueLike() then
            -- In roguelike mode, we need to use the real coordinates
            local realX, realY = player.realX, player.realY
            local dist = math.sqrt((realX - orb.screenX)^2 + (realY - orb.screenY)^2)
            
            if dist < healingOrbs.size * 1.5 then
                healingOrbs.collectOrb(i)
                break -- Exit the loop since we removed an element
            end
        else
            -- In grid mode, we can just compare grid positions
            if px == orb.x and py == orb.y then
                healingOrbs.collectOrb(i)
                break -- Exit the loop since we removed an element
            end
        end
    end
end

-- Draw all healing orbs
function healingOrbs.draw(gridOffsetX, gridOffsetY)
    -- Parameters are not directly used here as orbs already have their screen positions
    -- calculated in the update function, but we need to accept them for consistency
    for _, orb in ipairs(healingOrbs.list) do
        -- Draw glow effect
        love.graphics.setColor(0, 0.8, 0.2, orb.glowAlpha * 0.3)
        love.graphics.circle("fill", orb.screenX, orb.screenY, healingOrbs.glowRadius * orb.pulseScale)
        
        -- Draw outer glow
        love.graphics.setColor(0.1, 0.9, 0.3, orb.glowAlpha * 0.5)
        love.graphics.circle("fill", orb.screenX, orb.screenY, healingOrbs.size * 1.3 * orb.pulseScale)
        
        -- Draw orb
        love.graphics.setColor(0.2, 1, 0.4, 0.9)
        love.graphics.circle("fill", orb.screenX, orb.screenY, healingOrbs.size * orb.pulseScale)
        
        -- Draw health cross symbol
        love.graphics.setColor(1, 1, 1, 0.9)
        local crossSize = healingOrbs.size * 0.5 * orb.pulseScale
        
        -- Vertical part of cross
        love.graphics.rectangle("fill", 
            orb.screenX - crossSize/6, 
            orb.screenY - crossSize, 
            crossSize/3, 
            crossSize*2)
        
        -- Horizontal part of cross
        love.graphics.rectangle("fill", 
            orb.screenX - crossSize, 
            orb.screenY - crossSize/6, 
            crossSize*2, 
            crossSize/3)
    end
end

-- Player collects an orb
function healingOrbs.collectOrb(index)
    -- Heal player to full health
    player.heal(healingOrbs.healAmount)
    
    -- Play heal sound
    local sounds = require("modules.init").getSounds()
    if sounds and sounds.heal then
        sounds.heal:play()
    elseif sounds and sounds.powerUp then
        sounds.powerUp:play()
    end
    
    -- Remove the orb
    table.remove(healingOrbs.list, index)
    
    -- Visual feedback effect could be added in player.lua
end

-- Reset the heal orbs system
function healingOrbs.reset()
    healingOrbs.list = {}
    healingOrbs.lastSpawnTime = 0
    healingOrbs.setNextSpawnTime()
end

return healingOrbs
