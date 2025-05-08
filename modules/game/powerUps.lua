local powerUps = {}
local config = require("modules.game.config")
local player = require("modules.game.player")
local enemies = require("modules.game.enemies")
local bullets = require("modules.game.bullets")
local engine = require("modules.game.engine")

-- Store the currently active power-up
powerUps.active = nil
powerUps.activeTime = 0
powerUps.activeDuration = 15  -- Default duration in seconds
powerUps.codingActive = false
powerUps.codingPrompt = ""
powerUps.codingInput = ""
powerUps.codingCursor = 0
powerUps.codingErrorMsg = ""
powerUps.showTypingInterface = false
powerUps.codingSuccessTime = 0
powerUps.availablePowerUps = {}

-- Define all available power-ups
powerUps.types = {
    {
        name = "Infinity",
        description = "Hold to shoot continuously",
        code = "power.infinity()",
        icon = "∞",
        color = {0.2, 0.8, 1},
        activate = function()
            player.autoFireEnabled = true
            player.autoFireCooldown = 0.1 -- Time between shots
        end,
        deactivate = function()
            player.autoFireEnabled = false
        end,
        unlockAt = 0
    },
    {
        name = "Agility",
        description = "Press SPACE to dash",
        code = "power.agility()",
        icon = "→",
        color = {0.2, 1, 0.4},
        activate = function()
            player.dashEnabled = true
            player.dashDistance = 3 -- Grid cells to dash
            player.dashCooldown = 2 -- Seconds between dashes
            player.currentDashCooldown = 0
        end,
        deactivate = function()
            player.dashEnabled = false
        end,
        unlockAt = 1
    },
    {
        name = "GodSpeed",
        description = "Move faster",
        code = "power.speed()",
        icon = "⚡",
        color = {1, 1, 0.2},
        activate = function()
            player.originalMoveCooldown = config.moveCooldown
            config.moveCooldown = config.moveCooldown * 0.4 -- 60% faster movement
        end,
        deactivate = function()
            config.moveCooldown = player.originalMoveCooldown
        end,
        unlockAt = 2
    },
    {
        name = "Forcefield",
        description = "Shield the engine",
        code = "power.shield()",
        icon = "❍",
        color = {0.8, 0.4, 1},
        activate = function()
            engine.shielded = true
        end,
        deactivate = function()
            engine.shielded = false
        end,
        unlockAt = 3
    },
    {
        name = "Singularity",
        description = "Wormhole sucks in enemies",
        code = "power.wormhole()",
        icon = "◉",
        color = {0.1, 0.1, 0.3},
        activate = function(gridOffsetX, gridOffsetY)
            -- Create wormhole at random position
            local gridSize = config.gridSize
            local x = love.math.random(2, gridSize - 1)
            local y = love.math.random(2, gridSize - 1)
            powerUps.wormholeX = gridOffsetX + (x - 1) * config.cellSize + config.cellSize / 2
            powerUps.wormholeY = gridOffsetY + (y - 1) * config.cellSize + config.cellSize / 2
            powerUps.wormholeRadius = 30
            powerUps.wormholeActive = true
            powerUps.wormholePullStrength = 150
        end,
        deactivate = function()
            powerUps.wormholeActive = false
        end,
        unlockAt = 4
    },
    {
        name = "Crash",
        description = "Kill enemies in radius",
        code = "power.crash()",
        icon = "✹",
        color = {1, 0.3, 0.3},
        activate = function()
            -- Crash creates a one-time effect, not a persistent one
            for i = #enemies.list, 1, -1 do
                local e = enemies.list[i]
                local px, py = player.getScreenPosition(powerUps.gridOffsetX, powerUps.gridOffsetY)
                local dist = math.sqrt((e.x - px)^2 + (e.y - py)^2)
                if dist < 200 then -- Crash radius
                    table.remove(enemies.list, i)
                end
            end
            
            -- Visual effect for crash
            powerUps.crashEffectActive = true
            powerUps.crashEffectTime = 0
            powerUps.crashEffectDuration = 1.5
            powerUps.crashEffectRadius = 0
            powerUps.crashEffectMaxRadius = 200
        end,
        deactivate = function()
            powerUps.crashEffectActive = false
        end,
        unlockAt = 5
    }
}

-- Initialize the power-up system
function powerUps.init(gridOffsetX, gridOffsetY)
    powerUps.gridOffsetX = gridOffsetX
    powerUps.gridOffsetY = gridOffsetY
    
    -- Seed the random number generator to ensure it's different each game
    love.math.setRandomSeed(love.timer.getTime() * 10000)
    
    -- Track previously offered power-ups to avoid repeats
    powerUps.recentlyOffered = {}
end

-- Update the power-up system
function powerUps.update(dt, absoluteCheckpoint)
    -- Update available power-ups based on checkpoint progress
    powerUps.updateAvailable(absoluteCheckpoint)
    
    -- Handle active power-ups
    if powerUps.active then
        powerUps.activeTime = powerUps.activeTime + dt
        
        -- Special case for wormhole power-up
        if powerUps.wormholeActive then
            for _, e in ipairs(enemies.list) do
                local dx = powerUps.wormholeX - e.x
                local dy = powerUps.wormholeY - e.y
                local dist = math.sqrt(dx*dx + dy*dy)
                
                if dist < 150 then
                    local strength = (1 - (dist / 150)) * powerUps.wormholePullStrength
                    local angle = math.atan2(dy, dx)
                    e.x = e.x + math.cos(angle) * strength * dt
                    e.y = e.y + math.sin(angle) * strength * dt
                    
                    -- Destroy enemies that get sucked into the center
                    if dist < 20 then
                        e.health = 0
                    end
                end
            end
        end
        
        -- Handle crash effect animation
        if powerUps.crashEffectActive then
            powerUps.crashEffectTime = powerUps.crashEffectTime + dt
            powerUps.crashEffectRadius = (powerUps.crashEffectTime / powerUps.crashEffectDuration) * powerUps.crashEffectMaxRadius
            
            if powerUps.crashEffectTime >= powerUps.crashEffectDuration then
                powerUps.crashEffectActive = false
            end
        end
        
        -- Handle autofire for Infinity power-up
        if player.autoFireEnabled then
            player.autoFireTimer = (player.autoFireTimer or 0) + dt
            if player.autoFireTimer >= player.autoFireCooldown then
                player.autoFireTimer = 0
                local px, py = player.getScreenPosition(powerUps.gridOffsetX, powerUps.gridOffsetY)
                local mx, my = love.mouse.getPosition()
                bullets.create(px, py, mx, my)
            end
        end
        
        -- Deactivate power-up when time is up
        if powerUps.activeTime >= powerUps.activeDuration then
            powerUps.deactivate()
        end
    end
    
    -- Handle typing interface
    if powerUps.showTypingInterface then
        if love.keyboard.isDown("escape") then
            powerUps.showTypingInterface = false
            powerUps.codingInput = ""
            powerUps.codingErrorMsg = ""
        end
        
        -- Showing success animation
        if powerUps.codingSuccessTime > 0 then
            powerUps.codingSuccessTime = powerUps.codingSuccessTime - dt
            if powerUps.codingSuccessTime <= 0 then
                powerUps.showTypingInterface = false
                powerUps.codingInput = ""
            end
        end
    end
end

-- Draw power-up UI and effects
function powerUps.draw(fonts)
    -- Draw active power-up indicator
    if powerUps.active then
        local ww, wh = love.graphics.getDimensions()
        local timeLeft = powerUps.activeDuration - powerUps.activeTime
        local remainingPercentage = timeLeft / powerUps.activeDuration
        
        -- Background
        love.graphics.setColor(0.1, 0.1, 0.1, 0.7)
        love.graphics.rectangle("fill", ww - 100, 60, 80, 80, 5, 5)
        
        -- Icon
        love.graphics.setFont(fonts.massive)
        love.graphics.setColor(powerUps.active.color)
        local iconWidth = fonts.massive:getWidth(powerUps.active.icon)
        love.graphics.print(powerUps.active.icon, ww - 60 - iconWidth/2, 70)
        
        -- Name
        love.graphics.setFont(fonts.small)
        love.graphics.setColor(1, 1, 1, 0.9)
        local nameWidth = fonts.small:getWidth(powerUps.active.name)
        love.graphics.print(powerUps.active.name, ww - 60 - nameWidth/2, 120)
        
        -- Timer bar
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.rectangle("fill", ww - 90, 140, 60, 5)
        love.graphics.setColor(0.8, 0.8, 0.2)
        love.graphics.rectangle("fill", ww - 90, 140, 60 * remainingPercentage, 5)
    end
    
    -- Draw wormhole if active
    if powerUps.wormholeActive then
        local pulseSize = 1 + math.sin(love.timer.getTime() * 5) * 0.2
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.circle("fill", powerUps.wormholeX, powerUps.wormholeY, powerUps.wormholeRadius * pulseSize * 1.2)
        love.graphics.setColor(0.1, 0, 0.3, 0.8)
        love.graphics.circle("fill", powerUps.wormholeX, powerUps.wormholeY, powerUps.wormholeRadius * pulseSize)
        love.graphics.setColor(0.5, 0.2, 1, 0.5)
        love.graphics.circle("line", powerUps.wormholeX, powerUps.wormholeY, 150) -- Pull radius
    end
    
    -- Draw crash effect if active
    if powerUps.crashEffectActive then
        local alpha = 1 - (powerUps.crashEffectTime / powerUps.crashEffectDuration)
        love.graphics.setColor(1, 0.3, 0.1, alpha * 0.7)
        local px, py = player.getScreenPosition(powerUps.gridOffsetX, powerUps.gridOffsetY)
        love.graphics.circle("fill", px, py, powerUps.crashEffectRadius)
        love.graphics.setColor(1, 0.5, 0.2, alpha)
        love.graphics.circle("line", px, py, powerUps.crashEffectRadius)
    end
    
    -- Draw typing interface
    if powerUps.showTypingInterface then
        local ww, wh = love.graphics.getDimensions()
        
        -- Semi-transparent background
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, ww, wh)
        
        -- Code editor box
        local boxWidth = 600
        local boxHeight = 200  -- Smaller height since simpler code
        local boxX = ww/2 - boxWidth/2
        local boxY = wh/2 - boxHeight/2 - 20
        
        -- Draw editor background
        love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
        love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight, 5, 5)
        love.graphics.setColor(0.3, 0.3, 0.3, 1)
        love.graphics.rectangle("line", boxX, boxY, boxWidth, boxHeight, 5, 5)
        
        -- Draw title
        love.graphics.setFont(fonts.large)
        love.graphics.setColor(0.8, 0.8, 0.8, 1)
        local title = "HACK ENGINE"
        local titleWidth = fonts.large:getWidth(title)
        love.graphics.print(title, ww/2 - titleWidth/2, boxY - 40)
        
        -- If there's a coding success
        if powerUps.codingSuccessTime > 0 then
            love.graphics.setFont(fonts.extraLarge)
            love.graphics.setColor(0.2, 1, 0.4)
            local successText = "HACK SUCCESSFUL"
            local sucessWidth = fonts.extraLarge:getWidth(successText)
            love.graphics.print(successText, ww/2 - sucessWidth/2, wh/2 - 20)
            
            love.graphics.setFont(fonts.large)
            love.graphics.setColor(0.9, 0.9, 0.9)
            local powerUpText = "POWER UP ACTIVATED: " .. powerUps.active.name
            local powerUpWidth = fonts.large:getWidth(powerUpText)
            love.graphics.print(powerUpText, ww/2 - powerUpWidth/2, wh/2 + 40)
            return
        end
        
        -- Draw power-up icon and description
        love.graphics.setFont(fonts.massive)
        love.graphics.setColor(powerUps.selectedPowerUp.color)
        local iconWidth = fonts.massive:getWidth(powerUps.selectedPowerUp.icon)  
        love.graphics.print(powerUps.selectedPowerUp.icon, boxX + 50, boxY + boxHeight/2 - 30)
        
        love.graphics.setFont(fonts.large)
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.print(powerUps.selectedPowerUp.name, boxX + 100, boxY + boxHeight/2 - 40)
        
        love.graphics.setFont(fonts.small)
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.print(powerUps.selectedPowerUp.description, boxX + 100, boxY + boxHeight/2 - 10)
        
        -- Prompt code (simplified, single line)
        love.graphics.setFont(fonts.large)
        love.graphics.setColor(0.3, 0.8, 1, 0.9)
        local codePromptX = boxX + boxWidth/2
        local codePromptY = boxY + boxHeight/2 + 30
        local codeWidth = fonts.large:getWidth(powerUps.codingPrompt)
        love.graphics.print(powerUps.codingPrompt, codePromptX - codeWidth/2, codePromptY)
        
        -- Draw input field
        local inputBoxY = boxY + boxHeight + 20
        love.graphics.setColor(0.15, 0.15, 0.15, 0.9)
        love.graphics.rectangle("fill", boxX, inputBoxY, boxWidth, 40, 5, 5)
        love.graphics.setColor(0.3, 0.3, 0.3, 1)
        love.graphics.rectangle("line", boxX, inputBoxY, boxWidth, 40, 5, 5)
        
        -- Draw input text
        love.graphics.setFont(fonts.large)  -- Larger font for better visibility
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(powerUps.codingInput, boxX + 10, inputBoxY + 8)
        
        -- Draw cursor
        local cursorPos = fonts.large:getWidth(powerUps.codingInput:sub(1, powerUps.codingCursor))
        if math.floor(love.timer.getTime() * 2) % 2 == 0 then
            love.graphics.setColor(1, 1, 1)
            love.graphics.rectangle("fill", boxX + 10 + cursorPos, inputBoxY + 8, 2, fonts.large:getHeight())
        end
        
        -- Draw error message if any
        if powerUps.codingErrorMsg ~= "" then
            love.graphics.setColor(1, 0.3, 0.3)
            love.graphics.print(powerUps.codingErrorMsg, boxX, inputBoxY + 50)
        end
        
        -- Draw instructions
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.setFont(fonts.small)
        love.graphics.print("Type the code exactly as shown. Press ESC to cancel. Press ENTER to submit.", boxX, boxY + boxHeight + 70)
    end
end

-- Handle key presses for the typing interface
function powerUps.keypressed(key)
    if not powerUps.showTypingInterface or powerUps.codingSuccessTime > 0 then return end
    
    if key == "return" then
        -- Check if input matches the prompt
        if powerUps.codingInput == powerUps.codingPrompt then
            -- Activate the power-up
            powerUps.activate(powerUps.selectedPowerUp)
            powerUps.codingSuccessTime = 3
        else
            powerUps.codingErrorMsg = "CODE MISMATCH - TRY AGAIN"
        end
    elseif key == "backspace" then
        if powerUps.codingCursor > 0 then
            local left = powerUps.codingInput:sub(1, powerUps.codingCursor - 1)
            local right = powerUps.codingInput:sub(powerUps.codingCursor + 1)
            powerUps.codingInput = left .. right
            powerUps.codingCursor = powerUps.codingCursor - 1
        end
    elseif key == "left" then
        powerUps.codingCursor = math.max(0, powerUps.codingCursor - 1)
    elseif key == "right" then
        powerUps.codingCursor = math.min(powerUps.codingInput:len(), powerUps.codingCursor + 1)
    end
end

-- Handle text input for the typing interface
function powerUps.textinput(text)
    if not powerUps.showTypingInterface or powerUps.codingSuccessTime > 0 then return end
    
    local left = powerUps.codingInput:sub(1, powerUps.codingCursor)
    local right = powerUps.codingInput:sub(powerUps.codingCursor + 1)
    powerUps.codingInput = left .. text .. right
    powerUps.codingCursor = powerUps.codingCursor + 1
end

-- Update the list of available power-ups based on checkpoint progress
function powerUps.updateAvailable(absoluteCheckpoint)
    powerUps.availablePowerUps = {}
    -- Default to checkpoint 0 if nil
    local checkpoint = absoluteCheckpoint or 0
    for _, powerUp in ipairs(powerUps.types) do
        if powerUp.unlockAt <= checkpoint then
            table.insert(powerUps.availablePowerUps, powerUp)
        end
    end
end

-- Show power-up selection interface at checkpoint
function powerUps.showSelectionAt(checkpoint)
    -- Only show if there are power-ups available
    if #powerUps.availablePowerUps == 0 then return end
    
    -- If we already have an active power-up, don't offer a new one
    if powerUps.active then return end
    
    -- Create a list of power-ups that weren't recently offered, favoring ones not recently seen
    local availableOptions = {}
    for i, powerUp in ipairs(powerUps.availablePowerUps) do
        local wasRecentlyOffered = false
        for _, recentName in ipairs(powerUps.recentlyOffered) do
            if powerUp.name == recentName then
                wasRecentlyOffered = true
                break
            end
        end
        
        if not wasRecentlyOffered then
            table.insert(availableOptions, powerUp)
        end
    end
    
    -- If we've exhausted all options, reset and use all available power-ups
    if #availableOptions == 0 then
        availableOptions = powerUps.availablePowerUps
        powerUps.recentlyOffered = {}
    end
    
    -- Select a random power-up from available ones
    local randomIndex = love.math.random(#availableOptions)
    powerUps.selectedPowerUp = availableOptions[randomIndex]
    
    -- Add to recently offered list (keep last 3)
    table.insert(powerUps.recentlyOffered, powerUps.selectedPowerUp.name)
    if #powerUps.recentlyOffered > 3 then
        table.remove(powerUps.recentlyOffered, 1)
    end
    
    -- Show typing interface
    powerUps.showTypingInterface = true
    powerUps.codingPrompt = powerUps.selectedPowerUp.code
    powerUps.codingInput = ""
    powerUps.codingCursor = 0
    powerUps.codingErrorMsg = ""
end

-- Activate a power-up
function powerUps.activate(powerUp)
    if powerUps.active then
        powerUps.deactivate()
    end
    
    powerUps.active = powerUp
    powerUps.activeTime = 0
    
    -- Call the power-up's activate function
    if powerUp.activate then
        powerUp.activate(powerUps.gridOffsetX, powerUps.gridOffsetY)
    end
end

-- Deactivate the current power-up
function powerUps.deactivate()
    if not powerUps.active then return end
    
    -- Call the power-up's deactivate function
    if powerUps.active.deactivate then
        powerUps.active.deactivate()
    end
    
    powerUps.active = nil
end

-- Reset the power-up system
function powerUps.reset()
    powerUps.deactivate()
    powerUps.showTypingInterface = false
    powerUps.codingInput = ""
    powerUps.codingErrorMsg = ""
    powerUps.codingSuccessTime = 0
    powerUps.wormholeActive = false
    powerUps.crashEffectActive = false
    
    -- Reset recently offered power-ups
    powerUps.recentlyOffered = {}
    
    -- Re-seed random generator
    love.math.setRandomSeed(love.timer.getTime() * 10000)
end

return powerUps
