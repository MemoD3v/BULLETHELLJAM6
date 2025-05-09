local ui = {}

-- Store player health for UI display
ui.playerHealth = 0
ui.playerMaxHealth = 100
ui.playerStatusFadeTimer = 0

-- Volume display UI
ui.volumeDisplayTimer = 0
ui.volumeDisplayDuration = 2.0  -- How long to show volume display after adjustment

function ui.drawGrid(gridOffsetX, gridOffsetY, gridSize, cellSize, gridColor)
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
    -- Semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    love.graphics.setFont(fonts.massive)
    love.graphics.setColor(1, 0, 0)
    local gameOverText = "GAME OVER"
    local gameOverWidth = fonts.massive:getWidth(gameOverText)
    love.graphics.print(gameOverText, 
                      love.graphics.getWidth()/2 - gameOverWidth/2, 
                      love.graphics.getHeight()/2 - 100)

    love.graphics.setFont(fonts.extraLarge)
    love.graphics.setColor(1, 1, 1)
    local scoreText = "FINAL SCORE: " .. score
    local scoreWidth = fonts.extraLarge:getWidth(scoreText)
    love.graphics.print(scoreText, 
                      love.graphics.getWidth()/2 - scoreWidth/2, 
                      love.graphics.getHeight()/2 + 20)

    love.graphics.setFont(fonts.large)
    local restartText = "Press R to restart"
    local restartWidth = fonts.large:getWidth(restartText)
    love.graphics.print(restartText, 
                      love.graphics.getWidth()/2 - restartWidth/2, 
                      love.graphics.getHeight()/2 + 80)
end

return ui