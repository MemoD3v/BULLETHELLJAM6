local loadingBar = {}
local config = require("modules.game.config")
local camera = require("modules.game.camera")

loadingBar.width = config.gridSize * config.cellSize * 0.95
loadingBar.height = config.loadingBarHeight
loadingBar.progress = 0
loadingBar.color = config.loadingBarColor
loadingBar.bgColor = config.loadingBarBgColor
loadingBar.text = config.loadingBarText
loadingBar.font = nil
loadingBar.active = false
loadingBar.currentCheckpoint = 0
loadingBar.currentPhase = 1
loadingBar.totalPhases = 2
loadingBar.checkpointsPerPhase = 5
loadingBar.totalCheckpoints = 10
loadingBar.checkpointTextAlpha = 0
loadingBar.checkpointTextTimer = 0
loadingBar.checkpointTextDuration = 2
loadingBar.tickFlash = nil
loadingBar.phaseTransitionActive = false
loadingBar.phaseTransitionTime = 0
loadingBar.phaseTransitionDuration = 3
loadingBar.absoluteCheckpointOffset = 0 -- Initialize offset to avoid nil arithmetic
loadingBar.absoluteCheckpoint = 0 -- Initialize the absolute checkpoint to avoid nil errors
loadingBar.checkpointFlash = nil
loadingBar.healFlash = nil -- For vampire mode healing effect

-- Function to heal the loading bar progress when in Vampire mode
function loadingBar.heal(amount)
    if not loadingBar.active then return end
    
    -- Add the amount to the progress, capped at 1.0 (100%)
    loadingBar.progress = math.min(1.0, loadingBar.progress + amount)
    
    -- Visual feedback for healing
    -- Flash green briefly to indicate healing
    if not loadingBar.healFlash then
        loadingBar.healFlash = 0.5 -- Start with 50% alpha
    else
        loadingBar.healFlash = math.max(loadingBar.healFlash, 0.5) -- Extend existing flash
    end
    
    -- Play heal sound
    if sounds and sounds.powerUp then
        local sounds = require("modules.init").getSounds()

        sounds.powerUp:stop()
        sounds.powerUp:play()
    end
end

function loadingBar.update(dt)
    if loadingBar.checkpointTextAlpha > 0 then
        loadingBar.checkpointTextTimer = loadingBar.checkpointTextTimer + dt
        loadingBar.checkpointTextAlpha = math.max(0, loadingBar.checkpointTextAlpha - dt/loadingBar.checkpointTextDuration)
    end

    if loadingBar.checkpointFlash then
        loadingBar.checkpointFlash = math.max(0, loadingBar.checkpointFlash - dt * 2)
        if loadingBar.checkpointFlash <= 0 then loadingBar.checkpointFlash = nil end
    end
    
    -- Handle phase transition if active
    if loadingBar.phaseTransitionActive then
        loadingBar.phaseTransitionTime = loadingBar.phaseTransitionTime + dt
        if loadingBar.phaseTransitionTime >= loadingBar.phaseTransitionDuration then
            loadingBar.phaseTransitionActive = false
            loadingBar.phaseTransitionTime = 0
            loadingBar.currentPhase = 2
            loadingBar.progress = 0  -- Reset progress for phase 2
            camera.shake(5, 2.0)  -- Stronger shake for phase transition
        end
        return -- Don't update other things during transition
    end

    if loadingBar.active then
        local oldProgress = loadingBar.progress
        loadingBar.progress = math.min(1, loadingBar.progress + dt * 0.01)

        local newCheckpoint = math.floor(loadingBar.progress * loadingBar.checkpointsPerPhase)
        
        -- Calculate absolute checkpoint (0-9) for difficulty scaling
        local oldCheckpoint = loadingBar.currentCheckpoint
        loadingBar.currentCheckpoint = math.floor(loadingBar.progress * loadingBar.totalCheckpoints)
        loadingBar.absoluteCheckpoint = loadingBar.absoluteCheckpointOffset + loadingBar.currentCheckpoint
        
        -- Play checkpoint sound if reached a new checkpoint
        if loadingBar.currentCheckpoint > oldCheckpoint then
            local sounds = require("modules.init").getSounds()
            if sounds and sounds.checkpoint then
                sounds.checkpoint:stop()
                sounds.checkpoint:play()
            end
            
            -- Switch to after-start music if we're past the first checkpoint and just starting
            if loadingBar.absoluteCheckpoint > 0 and oldCheckpoint == 0 then
                if sounds and sounds.musicBeforeStart and sounds.musicAfterStart then

                end
            end
        end
        
        -- Return true if we hit a new checkpoint
        if loadingBar.currentCheckpoint > oldCheckpoint then
            loadingBar.checkpointTextAlpha = 1
            loadingBar.checkpointTextTimer = 0
            loadingBar.checkpointReached = true

            camera.shake(2 + loadingBar.absoluteCheckpoint * 1.5, 1.5)
            loadingBar.checkpointFlash = 0.3
            
            -- Unlock nuke at first checkpoint
            if loadingBar.currentCheckpoint == 1 and oldCheckpoint == 0 then
                -- Unlock the passive nuke ability
                local player = require("modules.game.player")
                player.passiveNukeUnlocked = true
                player.nukeUnlockMessageTimer = 5.0 -- Display message for 5 seconds
                
                -- Play unlock sound
                local sounds = require("modules.init").getSounds()
                if sounds and sounds.powerUp then
                    sounds.powerUp:stop()
                    sounds.powerUp:play()
                end
            end
        end

        -- Phase transition check
        if loadingBar.progress >= 1 then
            -- Check if this game mode has an end condition
            local gameModes = require("modules.game.gameModes")
            
            if not gameModes.hasEndCondition() then
                -- Endless mode: Just reset progress and increase difficulty
                loadingBar.progress = 0
                loadingBar.currentPhase = loadingBar.currentPhase + 1 -- Increase phase for higher difficulty
                loadingBar.absoluteCheckpointOffset = loadingBar.absoluteCheckpointOffset + loadingBar.checkpointsPerPhase
                
                -- Play phase transition sound
                local sounds = require("modules.init").getSounds()
                if sounds and sounds.phaseComplete then
                    sounds.phaseComplete:stop()
                    sounds.phaseComplete:play()
                end
                
                -- Visual feedback
                loadingBar.checkpointTextAlpha = 1
                loadingBar.checkpointTextTimer = 0
                camera.shake(5, 2.0) -- Stronger shake for phase transition
            elseif loadingBar.currentPhase < loadingBar.totalPhases then
                -- Normal mode with phases: transition to next phase
                -- Play phase completion sound
                local sounds = require("modules.init").getSounds()
                if sounds and sounds.phaseComplete then
                    sounds.phaseComplete:stop()
                    sounds.phaseComplete:play()
                end
                
                loadingBar.phaseTransitionActive = true
                loadingBar.phaseTransitionTime = 0
                loadingBar.checkpointTextAlpha = 1
                loadingBar.checkpointTextTimer = 0
            else
                -- Game complete! Trigger victory
                local gameState = require("modules.game.gameState")
                gameState.setVictory(true)
                
                -- Play victory sound
                local sounds = require("modules.init").getSounds()
                if sounds and sounds.victory then
                    sounds.victory:stop()
                    sounds.victory:play()
                end
                
                -- Stop the loading bar progression
                loadingBar.active = false
            end
        end

        -- Update tick flash visual effects
        if not loadingBar.tickFlash then 
            loadingBar.tickFlash = {} 
        end
        
        local ticks = loadingBar.checkpointsPerPhase
        local progressBefore = loadingBar.progress - dt * 0.01 -- Approximate previous progress
        for i = 1, ticks - 1 do
            local threshold = i / ticks
            if progressBefore < threshold and loadingBar.progress >= threshold then
                loadingBar.tickFlash[i] = 0.3
            end
        end
    end

    -- Update tick flashes
    if loadingBar.tickFlash then
        for i, time in pairs(loadingBar.tickFlash) do
            loadingBar.tickFlash[i] = time - dt
            if loadingBar.tickFlash[i] <= 0 then
                loadingBar.tickFlash[i] = nil
            end
        end
    end
    
    -- Update heal flash effect for vampire mode
    if loadingBar.healFlash then
        loadingBar.healFlash = loadingBar.healFlash - dt * 2 -- Fade out quickly
        if loadingBar.healFlash <= 0 then
            loadingBar.healFlash = nil
        end
    end
end

function loadingBar.draw(gridOffsetX, gridOffsetY, fonts)
    if loadingBar.checkpointFlash then
        love.graphics.setColor(1, 0, 0, loadingBar.checkpointFlash)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    end

    local barX = gridOffsetX + (config.gridSize * config.cellSize - loadingBar.width) / 2
    local barY = gridOffsetY - 40

    -- Draw loading bar background
    love.graphics.setColor(loadingBar.bgColor)
    love.graphics.rectangle("fill", barX, barY, loadingBar.width, loadingBar.height)
    
    -- If recently healed, use a green color for the filled part
    if loadingBar.healFlash and loadingBar.healFlash > 0 then
        -- Blend between normal color and healing green based on the heal flash
        local r = loadingBar.color[1] * (1 - loadingBar.healFlash) + 0.2 * loadingBar.healFlash
        local g = loadingBar.color[2] * (1 - loadingBar.healFlash) + 1.0 * loadingBar.healFlash
        local b = loadingBar.color[3] * (1 - loadingBar.healFlash) + 0.4 * loadingBar.healFlash
        love.graphics.setColor(r, g, b)
    else
        love.graphics.setColor(loadingBar.color)
    end
    
    -- Draw filled part of loading bar
    love.graphics.rectangle("fill", barX, barY, loadingBar.width * loadingBar.progress, loadingBar.height)
    
    -- Healing effect for Vampire mode (green glow)
    if loadingBar.healFlash and loadingBar.healFlash > 0 then
        love.graphics.setColor(0.2, 1, 0.4, loadingBar.healFlash * 0.7)
        love.graphics.rectangle("fill", barX, barY, loadingBar.width, loadingBar.height)
    end

    -- Phase transition effect
    if loadingBar.phaseTransitionActive then
        local progress = loadingBar.phaseTransitionTime / loadingBar.phaseTransitionDuration
        local flashIntensity = math.abs(math.sin(progress * math.pi * 10))
        
        love.graphics.setColor(1, 0.5, 0, flashIntensity)
        love.graphics.rectangle("fill", barX, barY, loadingBar.width, loadingBar.height)
        
        -- Draw phase transition text
        love.graphics.setFont(fonts.massive)
        local text = "ENTERING PHASE 2"
        local textWidth = fonts.massive:getWidth(text)
        local flashText = math.sin(love.timer.getTime() * 15) > 0
        love.graphics.setColor(1, 0.3, 0, flashText and 1 or 0.7)
        love.graphics.print(text, 
                          love.graphics.getWidth()/2 - textWidth/2, 
                          love.graphics.getHeight()/2 - 150)
        return
    end

    -- Draw tick marks
    for i = 1, loadingBar.checkpointsPerPhase - 1 do
        local x = barX + i * (loadingBar.width / loadingBar.checkpointsPerPhase)
        local flashAlpha = loadingBar.tickFlash and loadingBar.tickFlash[i] or 0
        
        -- Bright flash when passing a tick
        if flashAlpha > 0 then
            love.graphics.setColor(1, 1, 1, flashAlpha)
            love.graphics.rectangle("fill", x - 2, barY - 2, 4, loadingBar.height + 4)
        end
        
        -- Regular tick mark
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.rectangle("fill", x, barY, 2, loadingBar.height)
    end
    
    -- Draw checkpoint and phase text - always show for modes with end conditions
    local gameModes = require("modules.game.gameModes")
    local isEndlessMode = gameModes.getCurrentMode().id == "endless"
    
    -- In non-endless modes or when checkpoint text is visible, show the checkpoint and phase info
    if (gameModes.hasEndCondition() or loadingBar.checkpointTextAlpha > 0) and fonts.medium then
        -- Make sure absoluteCheckpoint is initialized to prevent nil errors
        if not loadingBar.absoluteCheckpoint then loadingBar.absoluteCheckpoint = 0 end
        local checkpointNum = loadingBar.absoluteCheckpoint + 1
        
        -- Set the proper text alpha - always visible (but faded) in non-endless modes
        local textAlpha = (gameModes.hasEndCondition() and not isEndlessMode) and 0.75 or loadingBar.checkpointTextAlpha
        
        -- Only adjust the phase text for Endless mode
        local phaseText
        if isEndlessMode then
            -- Endless mode: just show PHASE without "OF totalPhases"
            phaseText = "PHASE " .. loadingBar.currentPhase
        else
            -- Normal modes: show phase count
            phaseText = "PHASE " .. loadingBar.currentPhase .. " OF " .. loadingBar.totalPhases
        end
        
        love.graphics.setFont(fonts.medium)
        love.graphics.setColor(1, 1, 1, textAlpha)
        local checkpointText = "CHECKPOINT " .. checkpointNum
        local textWidth = fonts.medium:getWidth(checkpointText)
        love.graphics.print(checkpointText, barX + loadingBar.width/2 - textWidth/2, barY - 30)
        
        love.graphics.setFont(fonts.small)
        local phaseWidth = fonts.small:getWidth(phaseText)
        love.graphics.print(phaseText, barX + loadingBar.width/2 - phaseWidth/2, barY - 60)
    end
    
    -- Draw progress percentage if bar is active
    if loadingBar.active and fonts.small then
        love.graphics.setFont(fonts.small)
        love.graphics.setColor(1, 1, 1, 0.7)
        
        local percentage = math.floor(loadingBar.progress * 100)
        local text = percentage .. "%"
        local textWidth = fonts.small:getWidth(text)
        
        love.graphics.print(text, barX + loadingBar.width/2 - textWidth/2, barY + loadingBar.height/2 - fonts.small:getHeight()/2)
    end
end

function loadingBar.activate()
    local sounds = require("modules.init").getSounds()
    
    loadingBar.active = true
    sounds.musicBeforeStart:stop()
    sounds.musicAfterStart:play()
end

function loadingBar.reset()
    loadingBar.progress = 0
    loadingBar.currentCheckpoint = 0
    loadingBar.currentPhase = 1
    loadingBar.active = false
    loadingBar.checkpointReached = false
    loadingBar.checkpointTextAlpha = 0
    loadingBar.checkpointTextTimer = 0
    loadingBar.tickFlash = nil
    loadingBar.phaseTransitionActive = false
    loadingBar.phaseTransitionTime = 0
    loadingBar.absoluteCheckpointOffset = 0
    loadingBar.absoluteCheckpoint = 0  -- Reset absolute checkpoint to prevent nil errors
    loadingBar.healFlash = nil
end

return loadingBar