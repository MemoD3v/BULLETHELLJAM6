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
powerUps.codingFailureTime = 0
powerUps.typingTimeLimit = 10  -- Time limit in seconds to type the code
powerUps.typingTimeRemaining = 0  -- Countdown timer
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
    -- Store grid offset for positioning calculations
    powerUps.gridOffsetX = gridOffsetX
    powerUps.gridOffsetY = gridOffsetY
    
    -- Seed the random number generator to ensure it's different each game
    local seed = os.time() + math.floor(love.timer.getTime() * 10000)
    print("Seeding random with: " .. seed)
    love.math.setRandomSeed(seed)
    
    -- Store recently offered power-ups to avoid showing the same ones repeatedly
    powerUps.recentlyOffered = {}  -- List of recently offered power-up names
    powerUps.selectedPowerUp = nil  -- Initialize to nil
    powerUps.lastCheckpoint = -1   -- Track the last checkpoint we offered at
end

-- Update the power-up system
function powerUps.update(dt, absoluteCheckpoint)
    -- Update available power-ups based on checkpoint progress
    powerUps.updateAvailable(absoluteCheckpoint)
    
    -- Handle typing interface timer
    if powerUps.showTypingInterface and powerUps.codingSuccessTime <= 0 and powerUps.codingFailureTime <= 0 then
        powerUps.typingTimeRemaining = powerUps.typingTimeRemaining - dt
        
        -- Time's up!
        if powerUps.typingTimeRemaining <= 0 then
            powerUps.codingFailureTime = 2  -- Show failure message for 2 seconds
            powerUps.codingErrorMsg = "TIME'S UP - HACK FAILED"
        end
    end
    
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
        
        -- Showing failure animation
        if powerUps.codingFailureTime > 0 then
            powerUps.codingFailureTime = powerUps.codingFailureTime - dt
            if powerUps.codingFailureTime <= 0 then
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
        
        -- If showing failure message, draw special screen
        if powerUps.codingFailureTime > 0 then
            love.graphics.setFont(fonts.extraLarge)
            love.graphics.setColor(1, 0.2, 0.2)
            local failText = "HACK FAILED"
            local failWidth = fonts.extraLarge:getWidth(failText)
            love.graphics.print(failText, ww/2 - failWidth/2, wh/2 - 30)
            
            love.graphics.setFont(fonts.large)
            love.graphics.setColor(0.9, 0.9, 0.9)
            local reasonText = powerUps.codingErrorMsg
            local reasonWidth = fonts.large:getWidth(reasonText)
            love.graphics.print(reasonText, ww/2 - reasonWidth/2, wh/2 + 30)
            return
        end
        
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
            local powerUpText = "POWER UP ACTIVATED: "
            
            -- Check if powerUps.active exists before accessing its name
            if powerUps.active and powerUps.active.name then
                powerUpText = powerUpText .. powerUps.active.name
            elseif powerUps.selectedPowerUp and powerUps.selectedPowerUp.name then
                -- Fallback to the selected power-up if active one isn't set yet
                powerUpText = powerUpText .. powerUps.selectedPowerUp.name
            else
                powerUpText = powerUpText .. "Unknown"
            end
            
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
        
        -- Draw time remaining bar
        local timeBarWidth = boxWidth - 40
        local timeBarHeight = 8
        local timeBarX = boxX + 20
        local timeBarY = boxY + boxHeight - 30
        local timePercentage = powerUps.typingTimeRemaining / powerUps.typingTimeLimit
        
        -- Background
        love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
        love.graphics.rectangle("fill", timeBarX, timeBarY, timeBarWidth, timeBarHeight, 2, 2)
        
        -- Time bar color changes as time decreases
        if timePercentage > 0.6 then
            love.graphics.setColor(0.2, 0.8, 0.2)  -- Green
        elseif timePercentage > 0.3 then
            love.graphics.setColor(0.8, 0.7, 0.2)  -- Yellow
        else
            love.graphics.setColor(0.8, 0.2, 0.2)  -- Red
        end
        
        -- Timer fill
        love.graphics.rectangle("fill", timeBarX, timeBarY, timeBarWidth * timePercentage, timeBarHeight, 2, 2)
        
        -- Time text
        love.graphics.setFont(fonts.small)
        love.graphics.setColor(1, 1, 1, 0.9)
        local timeText = math.ceil(powerUps.typingTimeRemaining) .. " SECONDS REMAINING"
        local timeTextWidth = fonts.small:getWidth(timeText)
        love.graphics.print(timeText, boxX + boxWidth/2 - timeTextWidth/2, timeBarY - 20)
        
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
    
    -- Count how many power-ups are available at each checkpoint level
    local powerUpsByLevel = {}
    
    -- First, add all power-ups that should be available at this checkpoint
    for _, powerUp in ipairs(powerUps.types) do
        if powerUp.unlockAt <= checkpoint then
            table.insert(powerUps.availablePowerUps, powerUp)
            
            -- Track power-ups by level for debugging
            powerUpsByLevel[powerUp.unlockAt] = (powerUpsByLevel[powerUp.unlockAt] or 0) + 1
        end
    end
    
    -- Debug print the available power-ups
    local checkpointVal = checkpoint or 0
    local debugMsg = "Checkpoint " .. checkpointVal .. ": Available power-ups: " .. #powerUps.availablePowerUps
    for level, count in pairs(powerUpsByLevel) do
        debugMsg = debugMsg .. ", Level " .. level .. ": " .. count
    end
    print(debugMsg)
    
    for i, powerUp in ipairs(powerUps.availablePowerUps) do
        if powerUp and powerUp.name and powerUp.unlockAt then
            print(" - " .. powerUp.name .. " (unlockAt: " .. powerUp.unlockAt .. ")")
        else
            print(" - Invalid power-up data at index " .. i)
        end
    end
end

-- Show power-up selection interface at checkpoint
function powerUps.showSelectionAt(checkpoint)
    -- Only show if there are power-ups available
    if #powerUps.availablePowerUps == 0 then return end
    
    -- If we already have an active power-up, don't offer a new one
    if powerUps.active then return end
    
    -- Debug the checkpoint values
    print("Showing selection at checkpoint: " .. tostring(checkpoint) .. ", last checkpoint: " .. tostring(powerUps.lastCheckpoint))
    
    -- Only skip re-randomization if we already have a selected power-up AND we're showing the interface
    -- We removed this check for now as it was preventing power-ups from appearing
    
    -- Save this checkpoint as the last one we've processed
    powerUps.lastCheckpoint = checkpoint
    
    -- Reseed the random number generator each time we show a selection
    -- This ensures true randomness between checkpoints
    local checkpointValue = checkpoint or 0
    local seed = os.time() + math.floor(love.timer.getTime() * 1000) + checkpointValue * 17
    print("Re-seeding random at checkpoint " .. tostring(checkpointValue) .. " with seed: " .. seed)
    love.math.setRandomSeed(seed)
    
    -- Force refresh available power-ups based on current checkpoint
    powerUps.updateAvailable(checkpoint)
    
    -- Create a list of power-ups that weren't recently offered
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
        print("Reset recently offered list - all power-ups now available")
    end
    
    -- Debug: print available options
    local checkpointStr = checkpoint or "nil"
    print("Checkpoint: " .. checkpointStr .. ", Available power-ups: " .. #powerUps.availablePowerUps .. ", Available options: " .. #availableOptions)
    for i, powerUp in ipairs(availableOptions) do
        print(i .. ": " .. powerUp.name .. " (unlockAt: " .. powerUp.unlockAt .. ")")
    end
    
    -- Select a random power-up from available ones
    local randomIndex = love.math.random(#availableOptions)
    powerUps.selectedPowerUp = availableOptions[randomIndex]
    
    if powerUps.selectedPowerUp and powerUps.selectedPowerUp.name then
        print("Selected power-up: " .. powerUps.selectedPowerUp.name)
    else
        print("Warning: No power-up was selected")
    end
    
    -- Add to recently offered list - just track the last one to ensure variety
    -- This guarantees we never get the same power-up twice in a row
    powerUps.recentlyOffered = {powerUps.selectedPowerUp.name}
    
    -- Show typing interface
    powerUps.showTypingInterface = true
    powerUps.codingPrompt = powerUps.selectedPowerUp.code
    powerUps.codingInput = ""
    powerUps.codingCursor = 0
    powerUps.codingErrorMsg = ""
    
    -- Reset the typing timer
    powerUps.typingTimeRemaining = powerUps.typingTimeLimit
    powerUps.codingFailureTime = 0
end

-- Activate a power-up
function powerUps.activate(powerUpName)
    -- Play power-up activation sound
    local sounds = require("modules.init").getSounds()
    if sounds and sounds.powerUp then
        sounds.powerUp:stop()
        sounds.powerUp:play()
    end
    
    -- Find the power-up
    local powerUpToActivate = nil
    for _, powerUp in ipairs(powerUps.types) do
        if powerUp.name == powerUpName then
            powerUpToActivate = powerUp
            break
        end
    end
    
    if powerUps.active then
        powerUps.deactivate()
    end
    
    powerUps.active = powerUpToActivate
    
    powerUps.activeTime = 0
    
    -- Call the power-up's activate function
    if powerUpToActivate and powerUpToActivate.activate then
        powerUpToActivate.activate(powerUps.gridOffsetX, powerUps.gridOffsetY)
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
    powerUps.codingFailureTime = 0
    powerUps.typingTimeRemaining = powerUps.typingTimeLimit
    powerUps.wormholeActive = false
    powerUps.crashEffectActive = false
    powerUps.lastCheckpoint = -1  -- Reset last checkpoint tracker
    
    -- Reset recently offered power-ups
    powerUps.recentlyOffered = {}
    powerUps.selectedPowerUp = nil
    
    -- Re-seed random generator
    local seed = os.time() + math.floor(love.timer.getTime() * 10000)
    print("Reset: Re-seeding random with: " .. seed)
    love.math.setRandomSeed(seed)
end

return powerUps
