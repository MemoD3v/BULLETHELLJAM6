local ui = {}

-- Store player health for UI display
ui.playerHealth = 0
ui.playerMaxHealth = 100
ui.playerStatusFadeTimer = 0

-- Volume display UI
ui.volumeDisplayTimer = 0
ui.volumeDisplayDuration = 2.0  -- How long to show volume display after adjustment

-- Player instructions UI
ui.instructionsActive = true -- Start with instructions visible
ui.instructionsDuration = 10.0 -- Show instructions for 10 seconds
ui.instructionsTimer = ui.instructionsDuration

-- Nuke UI
ui.nukeIconPulse = 0 -- For pulsing animation when nuke is ready

function ui.drawGrid(gridOffsetX, gridOffsetY, gridSize, cellSize, gridColor)
    -- Skip drawing the grid in RogueLike mode
    local gameModes = require("modules.game.gameModes")
    if gameModes.isRogueLike() then
        -- If in RogueLike mode, draw an expanded border (50% larger than the grid)
        local expansionFactor = 1.5 -- Match player movement expansion
        local origGridSize = gridSize * cellSize
        local expandedGridSize = origGridSize * expansionFactor
        local expansionAmount = (expandedGridSize - origGridSize) / 2
        
        -- Draw the expanded border
        love.graphics.setColor(gridColor[1], gridColor[2], gridColor[3], 0.7) -- Semi-transparent border
        love.graphics.setLineWidth(4) -- Thicker border line
        love.graphics.rectangle("line", 
            gridOffsetX - expansionAmount, 
            gridOffsetY - expansionAmount, 
            expandedGridSize, 
            expandedGridSize)
        return
    end
    
    -- Draw normal grid for other modes
    love.graphics.setColor(gridColor)
    love.graphics.setLineWidth(2)
    for x = 0, gridSize do
        love.graphics.line(gridOffsetX + x * cellSize, gridOffsetY, 
                          gridOffsetX + x * cellSize, gridOffsetY + gridSize * cellSize)
    end
    for y = 0, gridSize do
        love.graphics.line(gridOffsetX, gridOffsetY + y * cellSize, 
                          gridOffsetX + gridSize * cellSize, gridOffsetY + y * cellSize)
    end
end

function ui.drawScore(score, font)
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("SCORE: " .. score, 20, 20)
end

function ui.updatePlayerStatus(health, maxHealth)
    ui.playerHealth = health or ui.playerHealth
    ui.playerMaxHealth = maxHealth or ui.playerMaxHealth
    
    -- If health changed, start the fade timer
    if health and health ~= ui.playerHealth then
        ui.playerStatusFadeTimer = 3.0 -- Show status for 3 seconds
    end
end

function ui.drawPlayerStatus(font)
    -- Draw health status in the top-right corner
    love.graphics.setFont(font)
    
    -- Draw current game mode in the top-right corner
    local gameModes = require("modules.game.gameModes")
    local currentMode = gameModes.getCurrentMode()
    if currentMode then
        love.graphics.setColor(0.8, 0.8, 1.0, 0.7)
        love.graphics.print("MODE: " .. currentMode.name, love.graphics.getWidth() - 150, 50)
    end
    
    -- Only show detailed status if fade timer is active
    if ui.playerStatusFadeTimer > 0 then
        ui.playerStatusFadeTimer = ui.playerStatusFadeTimer - love.timer.getDelta()
        
        -- Background panel
        local statusWidth = 200
        local statusHeight = 60
        local statusX = love.graphics.getWidth() - statusWidth - 20
        local statusY = 20
        
        -- Fade out effect near the end
        local alpha = ui.playerStatusFadeTimer > 1 and 0.8 or ui.playerStatusFadeTimer * 0.8
        
        love.graphics.setColor(0.1, 0.1, 0.1, alpha)
        love.graphics.rectangle("fill", statusX, statusY, statusWidth, statusHeight, 5, 5)
        love.graphics.setColor(0.3, 0.3, 0.3, alpha)
        love.graphics.rectangle("line", statusX, statusY, statusWidth, statusHeight, 5, 5)
        
        -- Health text
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.print("HEALTH: " .. math.floor(ui.playerHealth) .. "/" .. ui.playerMaxHealth, 
                         statusX + 10, statusY + 10)
        
        -- Health bar
        local barWidth = statusWidth - 20
        local barHeight = 15
        local barX = statusX + 10
        local barY = statusY + 35
        
        -- Health bar background
        love.graphics.setColor(0.2, 0.2, 0.2, alpha)
        love.graphics.rectangle("fill", barX, barY, barWidth, barHeight, 2, 2)
        
        -- Health bar fill
        local healthPercent = ui.playerHealth / ui.playerMaxHealth
        
        -- Choose color based on health percentage
        local r, g, b = 0.2, 0.8, 0.2 -- Green for high health
        if healthPercent < 0.6 then
            r, g, b = 0.8, 0.8, 0.2 -- Yellow for medium health
        end
        if healthPercent < 0.3 then
            r, g, b = 0.8, 0.2, 0.2 -- Red for low health
        end
        
        love.graphics.setColor(r, g, b, alpha)
        love.graphics.rectangle("fill", barX, barY, barWidth * healthPercent, barHeight, 2, 2)
    else
        -- Always show a simple health indicator in the corner
        local healthPercent = ui.playerHealth / ui.playerMaxHealth
        local r, g, b = 0.2, 0.8, 0.2
        if healthPercent < 0.6 then r, g, b = 0.8, 0.8, 0.2 end
        if healthPercent < 0.3 then r, g, b = 0.8, 0.2, 0.2 end
        
        love.graphics.setColor(r, g, b, 0.8)
        love.graphics.print("HP: " .. math.floor(ui.playerHealth), 
                         love.graphics.getWidth() - 80, 20)
    end
end

function ui.showVolumeDisplay()
    ui.volumeDisplayTimer = ui.volumeDisplayDuration
end

function ui.drawVolumeDisplay(font, volume)
    if ui.volumeDisplayTimer <= 0 then return end
    
    ui.volumeDisplayTimer = ui.volumeDisplayTimer - love.timer.getDelta()
    
    -- Background panel
    local displayWidth = 200
    local displayHeight = 100
    local displayX = love.graphics.getWidth() / 2 - displayWidth / 2
    local displayY = love.graphics.getHeight() - displayHeight - 20
    
    -- Fade out effect near the end
    local alpha = math.min(1, ui.volumeDisplayTimer)
    
    -- Draw background
    love.graphics.setColor(0, 0, 0, 0.7 * alpha)
    love.graphics.rectangle("fill", displayX, displayY, displayWidth, displayHeight)
    love.graphics.setColor(0.4, 0.4, 0.4, alpha)
    love.graphics.rectangle("line", displayX, displayY, displayWidth, displayHeight)
    
    -- Draw volume information
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1, alpha)
    
    -- Title
    love.graphics.print("VOLUME SETTINGS", displayX + 10, displayY + 10)
    
    -- Master volume
    local masterBarWidth = displayWidth - 20
    local barHeight = 10
    local barY = displayY + 40
    
    love.graphics.print("Master: " .. math.floor(volume.master * 100) .. "%", displayX + 10, barY - 15)
    love.graphics.setColor(0.2, 0.2, 0.2, alpha)
    love.graphics.rectangle("fill", displayX + 10, barY, masterBarWidth, barHeight)
    love.graphics.setColor(0.8, 0.8, 0.8, alpha)
    love.graphics.rectangle("fill", displayX + 10, barY, masterBarWidth * volume.master, barHeight)
    
    -- Music volume
    barY = displayY + 60
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.print("Music: " .. math.floor(volume.music * 100) .. "%", displayX + 10, barY - 15)
    love.graphics.setColor(0.2, 0.2, 0.2, alpha)
    love.graphics.rectangle("fill", displayX + 10, barY, masterBarWidth, barHeight)
    love.graphics.setColor(0.6, 0.8, 1, alpha)
    love.graphics.rectangle("fill", displayX + 10, barY, masterBarWidth * volume.music, barHeight)
    
    -- SFX volume
    barY = displayY + 80
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.print("SFX: " .. math.floor(volume.sfx * 100) .. "%", displayX + 10, barY - 15)
    love.graphics.setColor(0.2, 0.2, 0.2, alpha)
    love.graphics.rectangle("fill", displayX + 10, barY, masterBarWidth, barHeight)
    love.graphics.setColor(1, 0.8, 0.6, alpha)
    love.graphics.rectangle("fill", displayX + 10, barY, masterBarWidth * volume.sfx, barHeight)
end

function ui.reset()
    ui.playerHealth = 0
    ui.playerMaxHealth = 100
    ui.playerStatusFadeTimer = 0
    ui.volumeDisplayTimer = 0
end

function ui.drawGameOver(score, fonts)
    -- Check if this is a victory or defeat
    local gameState = require("modules.game.gameState")
    local isVictory = gameState.isVictory()
    
    -- Semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    love.graphics.setFont(fonts.massive)
    
    if isVictory then
        -- Victory screen (green colors)
        love.graphics.setColor(0.2, 0.8, 0.2)
        local victoryText = "VICTORY!"
        local victoryWidth = fonts.massive:getWidth(victoryText)
        love.graphics.print(victoryText, 
                          love.graphics.getWidth()/2 - victoryWidth/2, 
                          love.graphics.getHeight()/2 - 100)
                          
        -- Display mission accomplished message
        love.graphics.setFont(fonts.large)
        love.graphics.setColor(0.8, 1.0, 0.8)
        local missionText = "System stabilized! Glitch contained."
        local missionWidth = fonts.large:getWidth(missionText)
        love.graphics.print(missionText,
                          love.graphics.getWidth()/2 - missionWidth/2,
                          love.graphics.getHeight()/2 - 40)
    else
        -- Defeat screen (red colors)
        love.graphics.setColor(1, 0, 0)
        local gameOverText = "GAME OVER"
        local gameOverWidth = fonts.massive:getWidth(gameOverText)
        love.graphics.print(gameOverText, 
                          love.graphics.getWidth()/2 - gameOverWidth/2, 
                          love.graphics.getHeight()/2 - 100)
                          
        -- Display mission failed message
        love.graphics.setFont(fonts.large)
        love.graphics.setColor(1.0, 0.8, 0.8)
        local missionText = "System corruption overwhelming! Mission failed."
        local missionWidth = fonts.large:getWidth(missionText)
        love.graphics.print(missionText,
                          love.graphics.getWidth()/2 - missionWidth/2,
                          love.graphics.getHeight()/2 - 40)
    end

    -- Display final score for both victory and defeat
    love.graphics.setFont(fonts.extraLarge)
    love.graphics.setColor(1, 1, 1)
    local scoreText = "FINAL SCORE: " .. score
    local scoreWidth = fonts.extraLarge:getWidth(scoreText)
    love.graphics.print(scoreText, 
                      love.graphics.getWidth()/2 - scoreWidth/2, 
                      love.graphics.getHeight()/2 + 20)

    -- Display game mode
    love.graphics.setFont(fonts.large)
    local gameModes = require("modules.game.gameModes")
    local modeText = "Mode: " .. gameModes.getCurrentMode().name
    local modeWidth = fonts.large:getWidth(modeText)
    love.graphics.print(modeText,
                      love.graphics.getWidth()/2 - modeWidth/2,
                      love.graphics.getHeight()/2 + 60)
                      
    -- Show restart instructions
    love.graphics.setFont(fonts.medium)
    love.graphics.setColor(0.7, 0.7, 0.7)
    
    local restartText = ""
    if gameModes.hasEndCondition() then
        restartText = "Press R to restart or M for menu"
    else
        restartText = "Press M to return to menu"
    end
    
    local restartWidth = fonts.medium:getWidth(restartText)
    love.graphics.print(restartText, 
                      love.graphics.getWidth()/2 - restartWidth/2, 
                      love.graphics.getHeight()/2 + 100)
end

-- Function to draw player instructions
function ui.drawInstructions(fonts)
    -- Check if fonts are valid
    if not fonts or not fonts.small or not fonts.large or not fonts.extraLarge then
        print("Warning: Missing fonts in drawInstructions")
        return
    end
    
    -- Only draw if instructions are active
    if not ui.instructionsActive then return end
    
    -- Update timer
    ui.instructionsTimer = ui.instructionsTimer - love.timer.getDelta()
    if ui.instructionsTimer <= 0 then
        ui.instructionsActive = false
        return
    end
    
    -- Calculate fade effect (fade in quickly, fade out slowly)
    local alpha = 1.0
    if ui.instructionsTimer < 2.0 then
        -- Fade out during the last 2 seconds
        alpha = ui.instructionsTimer / 2.0
    elseif ui.instructionsTimer > ui.instructionsDuration - 0.5 then
        -- Fade in during the first 0.5 seconds
        alpha = (ui.instructionsDuration - ui.instructionsTimer) * 2.0
    end
    
    -- Semi-transparent background
    love.graphics.setColor(0, 0, 0, 0.7 * alpha)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Title
    love.graphics.setFont(fonts.extraLarge)
    love.graphics.setColor(1, 1, 1, alpha)
    local titleText = "GAME CONTROLS"
    local titleWidth = fonts.extraLarge:getWidth(titleText)
    love.graphics.print(titleText, 
                       love.graphics.getWidth()/2 - titleWidth/2, 
                       love.graphics.getHeight()/2 - 150)
    
    -- Draw instructions
    love.graphics.setFont(fonts.large)
    
    local instructions = {
        "WASD or Arrow Keys - Move character",
        "Mouse - Aim weapon",
        "Left Mouse Button - Shoot",
        "E - Interact with engine (when nearby)",
        "Space - Activate special ability (when available)",
        "Escape - Pause game"
    }
    
    local yOffset = love.graphics.getHeight()/2 - 80
    local lineHeight = 40
    
    for i, instruction in ipairs(instructions) do
        local instructionWidth = fonts.large:getWidth(instruction)
        love.graphics.print(instruction,
                         love.graphics.getWidth()/2 - instructionWidth/2,
                         yOffset + (i-1) * lineHeight)
    end
    
    -- Press any key to continue
    if ui.instructionsTimer < ui.instructionsDuration - 1.0 then
        love.graphics.setFont(fonts.small)
        local continueText = "Press any key to continue"
        local continueWidth = fonts.small:getWidth(continueText)
        
        -- Make it blink
        if math.floor(love.timer.getTime() * 2) % 2 == 0 then
            love.graphics.setColor(1, 1, 1, alpha * 0.8)
            love.graphics.print(continueText,
                             love.graphics.getWidth()/2 - continueWidth/2,
                             yOffset + (#instructions + 1) * lineHeight)
        end
    end
end

-- Function to dismiss instructions if key is pressed
function ui.dismissInstructions()
    if ui.instructionsActive and ui.instructionsTimer < ui.instructionsDuration - 1.0 then
        ui.instructionsActive = false
    end
end

-- Function to draw the passive nuke UI in the bottom-left corner
function ui.drawPassiveNuke(font)
    local player = require("modules.game.player")
    
    -- Draw the unlock message when the nuke is first unlocked
    if player.nukeUnlockMessageTimer > 0 then
        local messageAlpha = math.min(1.0, player.nukeUnlockMessageTimer)
        local ww, wh = love.graphics.getDimensions()
        
        -- Draw a semi-transparent background
        love.graphics.setColor(0, 0, 0, 0.7 * messageAlpha)
        love.graphics.rectangle("fill", ww/2 - 200, 100, 400, 80, 10, 10)
        love.graphics.setColor(1, 0.3, 0.3, messageAlpha)
        love.graphics.rectangle("line", ww/2 - 200, 100, 400, 80, 10, 10)
        
        -- Draw the message
        love.graphics.setFont(font)
        love.graphics.setColor(1, 1, 1, messageAlpha)
        local message = "NUKE ABILITY UNLOCKED!"
        local subMessage = "Press Q when charged to clear the screen"
        
        local messageWidth = font:getWidth(message)
        local subMessageWidth = font:getWidth(subMessage)
        
        love.graphics.print(message, ww/2 - messageWidth/2, 120)
        love.graphics.print(subMessage, ww/2 - subMessageWidth/2, 150)
    end
    
    -- Only draw the nuke UI if it's unlocked
    if not player.passiveNukeUnlocked then
        return
    end
    
    -- Update pulsing animation if nuke is ready
    if player.passiveNukeReady then
        ui.nukeIconPulse = (ui.nukeIconPulse + love.timer.getDelta() * 3) % (math.pi * 2)
    else
        ui.nukeIconPulse = 0
    end
    
    -- Nuke icon position (bottom-left corner)
    local iconSize = 40
    local iconX = 20
    local iconY = love.graphics.getHeight() - iconSize - 20
    
    -- Draw nuke icon background
    local bgAlpha = 0.6
    love.graphics.setColor(0.1, 0.1, 0.1, bgAlpha)
    love.graphics.rectangle("fill", iconX - 5, iconY - 5, iconSize + 10, iconSize + 10, 5, 5)
    love.graphics.setColor(0.3, 0.3, 0.3, bgAlpha)
    love.graphics.rectangle("line", iconX - 5, iconY - 5, iconSize + 10, iconSize + 10, 5, 5)
    
    -- Draw charge progress circle
    love.graphics.setLineWidth(3)
    
    -- Background circle (gray)
    love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
    love.graphics.circle("line", iconX + iconSize/2, iconY + iconSize/2, iconSize/2 - 2)
    
    -- Progress arc (changes color based on charge)
    local progress = player.passiveNukeCharge / player.passiveNukeMaxCharge
    local startAngle = -math.pi/2 -- Start at top
    local endAngle = startAngle + (math.pi * 2 * progress)
    
    local segments = 30
    local r, g, b = 1, 0.6, 0.2 -- Orange color for charging
    
    if player.passiveNukeReady then
        -- Use pulsing red when fully charged
        local pulse = (math.sin(ui.nukeIconPulse) + 1) / 2 -- 0 to 1 pulsing value
        r = 1
        g = 0.2 + pulse * 0.3
        b = 0.2
    end
    
    love.graphics.setColor(r, g, b, 0.9)
    
    -- Draw progress arc using line segments
    if progress > 0 and progress < 1 then
        local lastX = iconX + iconSize/2 + math.cos(startAngle) * (iconSize/2 - 2)
        local lastY = iconY + iconSize/2 + math.sin(startAngle) * (iconSize/2 - 2)
        
        for i = 1, segments do
            local ratio = i / segments
            local angle = startAngle + (endAngle - startAngle) * ratio
            if angle > startAngle and angle <= endAngle then
                local newX = iconX + iconSize/2 + math.cos(angle) * (iconSize/2 - 2)
                local newY = iconY + iconSize/2 + math.sin(angle) * (iconSize/2 - 2)
                love.graphics.line(lastX, lastY, newX, newY)
                lastX, lastY = newX, newY
            end
        end
    elseif progress >= 1 then
        -- Draw full circle when charged
        love.graphics.circle("line", iconX + iconSize/2, iconY + iconSize/2, iconSize/2 - 2)
    end
    
    -- Draw nuke icon
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.setFont(font)
    local iconText = "💥" -- Unicode explosion symbol
    local textWidth = font:getWidth(iconText)
    local textHeight = font:getHeight()
    love.graphics.print(iconText, iconX + iconSize/2 - textWidth/2, iconY + iconSize/2 - textHeight/2)
    
    -- Draw "Q" key prompt below the icon if nuke is ready
    if player.passiveNukeReady then
        love.graphics.setColor(1, 1, 1, 0.9)
        local keyPrompt = "[Q]"
        local promptWidth = font:getWidth(keyPrompt)
        love.graphics.print(keyPrompt, iconX + iconSize/2 - promptWidth/2, iconY + iconSize + 5)
    end
end

return ui