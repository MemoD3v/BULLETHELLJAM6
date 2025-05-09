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

loadingBar.checkpointFlash = nil

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
                    sounds.musicBeforeStart:stop()
                    sounds.musicAfterStart:play()
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
        end

        -- Phase transition check
        if loadingBar.progress >= 1 and loadingBar.currentPhase < loadingBar.totalPhases then
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
            return
        end

        if not loadingBar.tickFlash then loadingBar.tickFlash = {} end
        local ticks = loadingBar.checkpointsPerPhase
        for i = 1, ticks - 1 do
            local threshold = i / ticks
            if oldProgress < threshold and loadingBar.progress >= threshold then
                loadingBar.tickFlash[i] = 0.3
            end
        end
    end

    if loadingBar.tickFlash then
        for i, time in pairs(loadingBar.tickFlash) do
            loadingBar.tickFlash[i] = time - dt
            if loadingBar.tickFlash[i] <= 0 then
                loadingBar.tickFlash[i] = nil
            end
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

    love.graphics.setColor(loadingBar.bgColor)
    love.graphics.rectangle("fill", barX, barY, loadingBar.width, loadingBar.height)

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

    -- Change color based on phase
    local phaseColor
    if loadingBar.currentPhase == 2 then
        phaseColor = {1, 0.4, 0} -- Orange for phase 2
    else
        phaseColor = loadingBar.color -- Use default color for phase 1
    end
    
    local r, g, b = unpack(phaseColor)
    local animFactor = 0.5 + 0.5 * math.sin(love.timer.getTime() * 4)
    love.graphics.setColor(r * animFactor, g * animFactor, b * animFactor)
    love.graphics.rectangle("fill", barX, barY, loadingBar.width * loadingBar.progress, loadingBar.height)

    local numTicks = loadingBar.checkpointsPerPhase
    for i = 1, numTicks - 1 do
        local progressPerTick = i / numTicks
        local tickX = barX + loadingBar.width * progressPerTick

        local flash = loadingBar.tickFlash and loadingBar.tickFlash[i]
        if flash then
            local alpha = math.min(1, flash * 5)
            love.graphics.setColor(1, 1, 0.3, alpha)
        elseif loadingBar.progress >= progressPerTick then
            love.graphics.setColor(1, 1, 1, 1)
        else
            love.graphics.setColor(1, 1, 1, 0.2)
        end
        love.graphics.setLineWidth(2)
        love.graphics.line(tickX, barY, tickX, barY + loadingBar.height)
    end

    love.graphics.setFont(loadingBar.font)
    love.graphics.setColor(1, 1, 1)
    
    -- Update text based on phase
    local displayText = loadingBar.text
    if loadingBar.currentPhase == 2 then
        displayText = loadingBar.text .. " FINALIZING"
    end
    
    local textWidth = loadingBar.font:getWidth(displayText)
    love.graphics.print(displayText, barX + (loadingBar.width - textWidth) / 2, barY - 30)
    
    -- Show phase indicator
    local phaseText = "PHASE " .. loadingBar.currentPhase .. "/" .. loadingBar.totalPhases
    local phaseWidth = loadingBar.font:getWidth(phaseText)
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.print(phaseText, barX + loadingBar.width - phaseWidth, barY + loadingBar.height + 5)

    -- Calculate absolute checkpoint for display
    local absoluteCheckpoint = (loadingBar.currentPhase - 1) * loadingBar.checkpointsPerPhase + loadingBar.currentCheckpoint
    local checkpointText = "CHECKPOINT: " .. absoluteCheckpoint .. "/" .. loadingBar.totalCheckpoints
    love.graphics.print(checkpointText, barX, barY + loadingBar.height + 5)

    if loadingBar.checkpointTextAlpha > 0 then
        local messages = {
            "UNSTABLE GAME DETECTED, CRASH EXPECTED",
            "ANTI-CHEAT COUNTERMEASURES DETECTED",
            "ADMIN PRIVILEGES ESCALATION REQUIRED",
            "MEMORY BUFFER OVERFLOW IMMINENT",
            "GAME CRASH PROBABILITY INCREASING"
        }
        
        -- Choose a message based on checkpoint
        local messageIndex = (absoluteCheckpoint % #messages) + 1
        local text = messages[messageIndex]
        
        love.graphics.setFont(fonts.massive)

        local flash = math.sin(loadingBar.checkpointTextTimer * 15) > 0
        local alpha = loadingBar.checkpointTextAlpha * (flash and 1 or 0.3)

        love.graphics.setColor(1, 0, 0, alpha)
        local textWidth = fonts.massive:getWidth(text)
        love.graphics.print(text, 
                          love.graphics.getWidth()/2 - textWidth/2, 
                          love.graphics.getHeight()/2 - 150)
    end
end

function loadingBar.activate()
    loadingBar.active = true
end

function loadingBar.reset()
    loadingBar.progress = 0
    loadingBar.active = false
    loadingBar.currentCheckpoint = 0
    loadingBar.currentPhase = 1
    loadingBar.tickFlash = nil
    loadingBar.checkpointTextAlpha = 0
    loadingBar.checkpointReached = false
    loadingBar.checkpointFlash = nil
    loadingBar.phaseTransitionActive = false
    loadingBar.phaseTransitionTime = 0
    loadingBar.absoluteCheckpointOffset = 0 -- Reset the offset on game reset
end

return loadingBar