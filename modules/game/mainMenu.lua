local mainMenu = {}

local gameModes = require("modules.game.gameModes")

mainMenu.transitionState = "none"  -- "none", "out", "in"
mainMenu.transitionTimer = 0
mainMenu.transitionDuration = 0.5  -- seconds

mainMenu.active = true
mainMenu.currentScreen = "main"
mainMenu.hoveredOption = nil
mainMenu.animTimer = 0
mainMenu.titleScale = 1.0
mainMenu.titleGlitchText = "GLITCH IN THE GRID"
mainMenu.lastTitleChange = 0
mainMenu.selectedOption = 1
mainMenu.modeSelectionIndex = 1

mainMenu.mainOptions = {
    { text = "Play Game", action = "play" },
    { text = "Game Modes", action = "modes" },
    { text = "Exit Game", action = "exit" }
}

mainMenu.sideOptions = {
    { text = "Settings", action = "settings" },
    { text = "Credits", action = "credits" }
}

-- Audio settings variables
mainMenu.audioSettings = {
    masterVolume = 1.0,
    musicVolume = 1.0,
    sfxVolume = 1.0,
    sliderWidth = 200,
    sliderHeight = 10,
    draggingSlider = nil  -- Which slider is being dragged
}

-- Credits information
mainMenu.credits = {
    { label = "Development by", value = "Hakashi Katake and MemoDev" },
    { label = "Art by", value = "Boony62" },
    { label = "Music by", value = "MemoDev" }
}

mainMenu.buttonWidth = 200
mainMenu.buttonHeight = 50
mainMenu.buttonSpacing = 20

function mainMenu.init(fonts)
    mainMenu.fonts = fonts
    mainMenu.active = true
    mainMenu.currentScreen = "main"
    mainMenu.animTimer = 0
    gameModes.init()
end

function mainMenu.update(dt)
    if not mainMenu.active then return end
    
    -- Update transition timer if transitioning
    if mainMenu.transitionState ~= "none" then
        mainMenu.transitionTimer = mainMenu.transitionTimer + dt
        if mainMenu.transitionTimer >= mainMenu.transitionDuration then
            if mainMenu.transitionState == "out" then
                mainMenu.active = false
                mainMenu.transitionState = "none"
            end
        end
    end
    
    -- Only update animations if not transitioning out
    if mainMenu.transitionState ~= "out" then
        mainMenu.animTimer = mainMenu.animTimer + dt
        mainMenu.titleScale = 1.0 + 0.05 * math.sin(mainMenu.animTimer * 3)

        if mainMenu.animTimer - mainMenu.lastTitleChange > 1 then
            mainMenu.lastTitleChange = mainMenu.animTimer
            if math.random() < 0.3 then
                mainMenu.titleGlitchText = "GL1TCH !N THE GR!D"
            else
                mainMenu.titleGlitchText = "GLITCH IN THE GRID"
            end
        end
    end
end

function mainMenu.draw()
    if not mainMenu.active and mainMenu.transitionState ~= "out" then return end

    -- Background effect
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    
    -- Draw grid background
    love.graphics.setColor(0.1, 0.1, 0.2, 0.3)
    local gridSize = 30
    for x = 0, screenW, gridSize do
        love.graphics.line(x, 0, x, screenH)
    end
    for y = 0, screenH, gridSize do
        love.graphics.line(0, y, screenW, y)
    end
    
    -- Draw appropriate screen based on current state
    if mainMenu.currentScreen == "main" then
        mainMenu.drawMainScreen()
    elseif mainMenu.currentScreen == "modes" then
        mainMenu.drawModesScreen()
    elseif mainMenu.currentScreen == "settings" then
        mainMenu.drawSettingsScreen()
    elseif mainMenu.currentScreen == "credits" then
        mainMenu.drawCreditsScreen()
    end
    
    -- Draw transition overlay
    if mainMenu.transitionState ~= "none" then
        local progress = mainMenu.transitionTimer / mainMenu.transitionDuration
        local alpha
        if mainMenu.transitionState == "out" then
            alpha = progress
        else
            alpha = 1 - progress
        end
        love.graphics.setColor(0, 0, 0, alpha)
        love.graphics.rectangle("fill", 0, 0, screenW, screenH)
    end
end

function mainMenu.drawGlitchPolygon()
    local cx, cy = love.graphics.getWidth()/2, love.graphics.getHeight()/2
    local sides = 8  -- Increased number of sides for more complex shape
    local radius = 120 + 30 * math.sin(mainMenu.animTimer * 2.5)
    local vertices = {}
    
    -- Create a seed for deterministic randomness based on time
    local seed = math.floor(mainMenu.animTimer * 10) % 100
    math.randomseed(seed)
    
    for i = 1, sides do
        local angle = (i / sides) * math.pi * 2 + mainMenu.animTimer * 0.5
        -- More controlled randomness
        local variance = 10 + 15 * math.sin(mainMenu.animTimer * 4 + i)
        local r = radius + variance
        table.insert(vertices, cx + math.cos(angle) * r)
        table.insert(vertices, cy + math.sin(angle) * r)
    end
    
    -- Outer glow
    for i = 1, 3 do
        local alpha = 0.1 - (i * 0.03)
        love.graphics.setColor(0.8, 0.2, 0.4, alpha)
        love.graphics.setLineWidth(8 + i * 3)
        love.graphics.polygon("line", vertices)
    end
    
    -- Fill with pulsing color
    local pulseVal = 0.3 + 0.2 * math.sin(mainMenu.animTimer * 3)
    love.graphics.setColor(0.8, pulseVal, 0.3 + pulseVal, 0.5)
    love.graphics.polygon("fill", vertices)
    
    -- Inner highlight
    love.graphics.setColor(1, 0.8, 0.9, 0.2 + 0.1 * math.sin(mainMenu.animTimer * 5))
    love.graphics.setLineWidth(2)
    love.graphics.polygon("line", vertices)
    
    -- Reset random seed and line width to not affect other parts of the game
    math.randomseed(os.time())
    love.graphics.setLineWidth(1)
end

function mainMenu.drawMainScreen()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local centerX = screenW / 2
    local titleY = 60

    love.graphics.setFont(mainMenu.fonts.massive)
    love.graphics.setColor(1, 0.4 + 0.1 * math.sin(mainMenu.animTimer * 10), 0.4)
    local titleText = mainMenu.titleGlitchText
    local titleWidth = mainMenu.fonts.massive:getWidth(titleText)
    local jitterX = math.random(-1, 1)
    local jitterY = math.random(-1, 1)

    love.graphics.push()
    love.graphics.translate(centerX + jitterX, titleY + jitterY)
    love.graphics.scale(mainMenu.titleScale, mainMenu.titleScale)
    love.graphics.print(titleText, -titleWidth/2, 0)
    love.graphics.pop()

    local currentMode = gameModes.getCurrentMode()
    love.graphics.setFont(mainMenu.fonts.small)
    love.graphics.setColor(0.8, 0.8, 0.8, 0.8)
    local modeText = "Mode: " .. currentMode.name
    local modeDesc = currentMode.description
    local modeWidth = mainMenu.fonts.small:getWidth(modeText)
    love.graphics.print(modeText, centerX - modeWidth/2, titleY + 80)

    local descWidth = mainMenu.fonts.small:getWidth(modeDesc)
    love.graphics.setColor(0.8, 0.8, 0.8, 0.6)
    love.graphics.print(modeDesc, centerX - descWidth/2, titleY + 100)

    local rightX = screenW - mainMenu.buttonWidth - 40
    local leftX = 40
    local baseY = screenH / 2 - (#mainMenu.mainOptions * (mainMenu.buttonHeight + mainMenu.buttonSpacing)) / 2

    love.graphics.setFont(mainMenu.fonts.large)
    mainMenu.hoveredOption = nil

    for i, option in ipairs(mainMenu.mainOptions) do
        local y = baseY + (i-1)*(mainMenu.buttonHeight + mainMenu.buttonSpacing)
        local mx, my = love.mouse.getPosition()
        local hovered = mx > rightX and mx < rightX + mainMenu.buttonWidth and my > y and my < y + mainMenu.buttonHeight
        local selected = (i == mainMenu.selectedOption and mainMenu.currentScreen == "main")

        if hovered then 
            mainMenu.hoveredOption = { side = "right", index = i }
            mainMenu.selectedOption = i
        end

        local pulse = (hovered or selected) and 5 * math.sin(mainMenu.animTimer * 6) or 0

        love.graphics.setColor((hovered or selected) and {0.4, 0.8, 1, 1} or {0.2, 0.3, 0.4, 0.7})
        love.graphics.rectangle("fill", rightX - pulse/2, y, mainMenu.buttonWidth + pulse, mainMenu.buttonHeight, 12, 12)

        love.graphics.setColor(1, 1, 1, 1)
        local textWidth = mainMenu.fonts.large:getWidth(option.text)
        love.graphics.print(option.text, rightX + mainMenu.buttonWidth/2 - textWidth/2, y + mainMenu.buttonHeight/2 - mainMenu.fonts.large:getHeight()/2)
    end

    for i, option in ipairs(mainMenu.sideOptions) do
        local y = baseY + (#mainMenu.mainOptions)*(mainMenu.buttonHeight + mainMenu.buttonSpacing) - i*(mainMenu.buttonHeight + mainMenu.buttonSpacing)
        local mx, my = love.mouse.getPosition()
        local hovered = mx > leftX and mx < leftX + mainMenu.buttonWidth and my > y and my < y + mainMenu.buttonHeight

        if hovered then mainMenu.hoveredOption = { side = "left", index = i } end
        love.graphics.setColor(hovered and {0.8, 0.5, 0.9, 0.9} or {0.3, 0.3, 0.4, 0.7})
        love.graphics.rectangle("fill", leftX, y, mainMenu.buttonWidth, mainMenu.buttonHeight, 12, 12)

        love.graphics.setColor(1, 1, 1, 1)
        local textWidth = mainMenu.fonts.large:getWidth(option.text)
        love.graphics.print(option.text, leftX + mainMenu.buttonWidth/2 - textWidth/2, y + mainMenu.buttonHeight/2 - mainMenu.fonts.large:getHeight()/2)
    end

    love.graphics.setFont(mainMenu.fonts.small)
    love.graphics.setColor(0.6, 0.6, 0.6, 0.5)
    local instructions = "Arrow Keys: Navigate   Enter: Select   Mouse: Click"
    local instructionsWidth = mainMenu.fonts.small:getWidth(instructions)
    love.graphics.print(instructions, centerX - instructionsWidth/2, screenH - 40)
end

function mainMenu.drawModesScreen()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local centerX = screenW / 2

    love.graphics.setFont(mainMenu.fonts.extraLarge)
    love.graphics.setColor(0.8, 0.2, 0.2)
    local titleText = "GAME MODES"
    local titleWidth = mainMenu.fonts.extraLarge:getWidth(titleText)
    love.graphics.print(titleText, centerX - titleWidth/2, 60)

    local modes = gameModes.getAllModes()
    local startY = 150

    love.graphics.setFont(mainMenu.fonts.large)

    for i, mode in ipairs(modes) do
        local buttonX = centerX - mainMenu.buttonWidth / 2
        local buttonY = startY + (i-1) * (mainMenu.buttonHeight + mainMenu.buttonSpacing)
        local mx, my = love.mouse.getPosition()
        local hovered = mx > buttonX and mx < buttonX + mainMenu.buttonWidth and my > buttonY and my < buttonY + mainMenu.buttonHeight
        local selected = (i == mainMenu.modeSelectionIndex)

        if hovered then
            mainMenu.modeSelectionIndex = i
        end

        local pulse = (hovered or selected) and 5 * math.sin(mainMenu.animTimer * 5) or 0

        if hovered or selected then
            love.graphics.setColor(0.3, 0.6, 0.9, 0.7)
        else
            love.graphics.setColor(0.2, 0.2, 0.3, 0.7)
        end

        love.graphics.rectangle("fill", buttonX - pulse/2, buttonY, mainMenu.buttonWidth + pulse, mainMenu.buttonHeight, 8, 8)

        if hovered or selected then
            love.graphics.setColor(1, 1, 1, 1)
        else
            love.graphics.setColor(0.8, 0.8, 0.8, 0.8)
        end

        local textWidth = mainMenu.fonts.large:getWidth(mode.name)
        love.graphics.print(mode.name, centerX - textWidth/2, buttonY + mainMenu.buttonHeight/2 - mainMenu.fonts.large:getHeight()/2)
    end

    if mainMenu.modeSelectionIndex <= #modes then
        local selectedMode = modes[mainMenu.modeSelectionIndex]
        love.graphics.setFont(mainMenu.fonts.small)
        love.graphics.setColor(0.8, 0.8, 0.8, 0.9)

        local descriptionPanelX = 20
        local descriptionPanelY = startY
        local descriptionPanelWidth = 200

        love.graphics.setColor(0.1, 0.1, 0.2, 0.7)
        love.graphics.rectangle("fill", descriptionPanelX - 10, descriptionPanelY - 10, 
                             descriptionPanelWidth + 20, 300, 8, 8)
        love.graphics.setColor(0.3, 0.3, 0.5, 0.5)
        love.graphics.rectangle("line", descriptionPanelX - 10, descriptionPanelY - 10, 
                             descriptionPanelWidth + 20, 300, 8, 8)

        love.graphics.setColor(1, 0.8, 0.2, 0.9)
        love.graphics.print("Description:", descriptionPanelX, descriptionPanelY)

        love.graphics.setColor(0.9, 0.9, 0.9, 0.8)
        love.graphics.printf(selectedMode.description, descriptionPanelX, descriptionPanelY + 25, descriptionPanelWidth, "left")

        local statsY = descriptionPanelY + 80
        love.graphics.setColor(0.7, 0.9, 1.0, 0.8)
        love.graphics.print("Starting Health: " .. selectedMode.startingHealth, descriptionPanelX, statsY)
        love.graphics.print("Enemy Spawn Rate: " .. selectedMode.enemySpawnMultiplier .. "x", descriptionPanelX, statsY + 25)
        love.graphics.print("Score Multiplier: " .. selectedMode.scoreMultiplier .. "x", descriptionPanelX, statsY + 50)
    end

    local backX, backY = 40, screenH - 100
    local buttonWidth, buttonHeight = 160, 50
    local mx, my = love.mouse.getPosition()
    local hovered = mx > backX and mx < backX + buttonWidth and my > backY and my < backY + buttonHeight

    love.graphics.setColor(hovered and {0.6, 0.6, 1, 0.9} or {0.3, 0.3, 0.5, 0.7})
    love.graphics.rectangle("fill", backX, backY, buttonWidth, buttonHeight, 12, 12)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Back", backX + buttonWidth / 2 - mainMenu.fonts.large:getWidth("Back") / 2, backY + buttonHeight / 2 - mainMenu.fonts.large:getHeight() / 2)

    love.graphics.setFont(mainMenu.fonts.small)
    love.graphics.setColor(0.6, 0.6, 0.6, 0.5)
    local instructions = "Arrow Keys: Navigate   Enter: Select   ESC: Back   Mouse: Click"
    local instructionsWidth = mainMenu.fonts.small:getWidth(instructions)
    love.graphics.print(instructions, centerX - instructionsWidth/2, screenH - 40)
end

-- Draw the Settings Screen
function mainMenu.drawSettingsScreen()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local centerX = screenW / 2
    
    -- Title
    love.graphics.setFont(mainMenu.fonts.extraLarge)
    love.graphics.setColor(0.9, 0.9, 1.0, 0.9)
    local title = "Audio Settings"
    local titleWidth = mainMenu.fonts.extraLarge:getWidth(title)
    love.graphics.print(title, centerX - titleWidth / 2, 60)
    
    -- Settings panel background
    love.graphics.setColor(0.1, 0.1, 0.2, 0.7)
    local panelWidth = 400
    local panelHeight = 300
    local panelX = centerX - panelWidth / 2
    local panelY = 120
    love.graphics.rectangle("fill", panelX, panelY, panelWidth, panelHeight, 10, 10)
    love.graphics.setColor(0.3, 0.3, 0.5, 0.5)
    love.graphics.rectangle("line", panelX, panelY, panelWidth, panelHeight, 10, 10)
    
    -- Draw sliders
    love.graphics.setFont(mainMenu.fonts.large)
    
    -- Master Volume
    local sliderY = panelY + 40
    love.graphics.setColor(0.8, 0.8, 1.0, 0.9)
    love.graphics.print("Master Volume", panelX + 30, sliderY)
    mainMenu.drawVolumeSlider("master", panelX + 30, sliderY + 40, mainMenu.audioSettings.sliderWidth)
    
    -- Music Volume
    sliderY = sliderY + 80
    love.graphics.setColor(0.8, 0.8, 1.0, 0.9)
    love.graphics.print("Music Volume", panelX + 30, sliderY)
    mainMenu.drawVolumeSlider("music", panelX + 30, sliderY + 40, mainMenu.audioSettings.sliderWidth)
    
    -- SFX Volume
    sliderY = sliderY + 80
    love.graphics.setColor(0.8, 0.8, 1.0, 0.9)
    love.graphics.print("SFX Volume", panelX + 30, sliderY)
    mainMenu.drawVolumeSlider("sfx", panelX + 30, sliderY + 40, mainMenu.audioSettings.sliderWidth)
    
    -- Back button
    local backX = 40
    local backY = screenH - 100
    local buttonWidth = 160
    local buttonHeight = 50
    local mx, my = love.mouse.getPosition()
    local hovered = mx > backX and mx < backX + buttonWidth and my > backY and my < backY + buttonHeight
    
    love.graphics.setColor(hovered and {0.6, 0.6, 1, 0.9} or {0.3, 0.3, 0.5, 0.7})
    love.graphics.rectangle("fill", backX, backY, buttonWidth, buttonHeight, 12, 12)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Back", backX + buttonWidth / 2 - mainMenu.fonts.large:getWidth("Back") / 2, backY + buttonHeight / 2 - mainMenu.fonts.large:getHeight() / 2)
    
    -- Instructions
    love.graphics.setFont(mainMenu.fonts.small)
    love.graphics.setColor(0.6, 0.6, 0.6, 0.5)
    local instructions = "Click and drag sliders to adjust volume"
    local instructionsWidth = mainMenu.fonts.small:getWidth(instructions)
    love.graphics.print(instructions, centerX - instructionsWidth/2, screenH - 40)
end

-- Draw volume slider with current value
function mainMenu.drawVolumeSlider(type, x, y, width)
    local height = mainMenu.audioSettings.sliderHeight
    local value = 0
    
    if type == "master" then
        value = mainMenu.audioSettings.masterVolume
    elseif type == "music" then
        value = mainMenu.audioSettings.musicVolume
    elseif type == "sfx" then
        value = mainMenu.audioSettings.sfxVolume
    end
    
    -- Background
    love.graphics.setColor(0.2, 0.2, 0.3, 0.8)
    love.graphics.rectangle("fill", x, y, width, height, height/2, height/2)
    
    -- Fill based on value
    love.graphics.setColor(0.4, 0.6, 1.0, 0.9)
    love.graphics.rectangle("fill", x, y, width * value, height, height/2, height/2)
    
    -- Slider handle
    love.graphics.setColor(0.9, 0.9, 1.0, 1.0)
    local handleX = x + width * value
    local handleSize = height * 2
    love.graphics.circle("fill", handleX, y + height/2, handleSize/2)
    
    -- Value text
    love.graphics.setFont(mainMenu.fonts.small)
    local valueText = math.floor(value * 100) .. "%"
    love.graphics.print(valueText, x + width + 10, y - 5)
end

-- Draw the Credits Screen
function mainMenu.drawCreditsScreen()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local centerX = screenW / 2
    
    -- Title
    love.graphics.setFont(mainMenu.fonts.extraLarge)
    love.graphics.setColor(0.9, 0.9, 1.0, 0.9)
    local title = "Credits"
    local titleWidth = mainMenu.fonts.extraLarge:getWidth(title)
    love.graphics.print(title, centerX - titleWidth / 2, 60)
    
    -- Credits panel background
    love.graphics.setColor(0.1, 0.1, 0.2, 0.7)
    local panelWidth = 500
    local panelHeight = 300
    local panelX = centerX - panelWidth / 2
    local panelY = 120
    love.graphics.rectangle("fill", panelX, panelY, panelWidth, panelHeight, 10, 10)
    love.graphics.setColor(0.3, 0.3, 0.5, 0.5)
    love.graphics.rectangle("line", panelX, panelY, panelWidth, panelHeight, 10, 10)
    
    -- Credits content
    love.graphics.setFont(mainMenu.fonts.large)
    local creditY = panelY + 50
    local spacing = 70
    
    for i, credit in ipairs(mainMenu.credits) do
        -- Label (what they did)
        love.graphics.setColor(0.7, 0.9, 1.0, 0.9)
        love.graphics.print(credit.label, panelX + 40, creditY)
        
        -- Value (who did it)
        love.graphics.setColor(1.0, 1.0, 1.0, 0.9)
        love.graphics.print(credit.value, panelX + 40, creditY + 30)
        
        creditY = creditY + spacing
    end
    
    -- Back button
    local backX = 40
    local backY = screenH - 100
    local buttonWidth = 160
    local buttonHeight = 50
    local mx, my = love.mouse.getPosition()
    local hovered = mx > backX and mx < backX + buttonWidth and my > backY and my < backY + buttonHeight
    
    love.graphics.setColor(hovered and {0.6, 0.6, 1, 0.9} or {0.3, 0.3, 0.5, 0.7})
    love.graphics.rectangle("fill", backX, backY, buttonWidth, buttonHeight, 12, 12)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Back", backX + buttonWidth / 2 - mainMenu.fonts.large:getWidth("Back") / 2, backY + buttonHeight / 2 - mainMenu.fonts.large:getHeight() / 2)
    
    -- Special thanks
    love.graphics.setFont(mainMenu.fonts.small)
    love.graphics.setColor(0.6, 0.6, 0.6, 0.5)
    local thanksText = "Special thanks to the LÖVE2D community"
    local thanksWidth = mainMenu.fonts.small:getWidth(thanksText)
    love.graphics.print(thanksText, centerX - thanksWidth/2, screenH - 40)
end

function mainMenu.mousepressed(x, y, button)
    if not mainMenu.active or button ~= 1 then return end
    local mx, my = x, y
    
    -- Check common back button for all screens except main
    if mainMenu.currentScreen ~= "main" then
        local backX = 40
        local backY = love.graphics.getHeight() - 100
        local buttonWidth = 160
        local buttonHeight = 50
        
        if mx > backX and mx < backX + buttonWidth and my > backY and my < backY + buttonHeight then
            mainMenu.currentScreen = "main"
            return
        end
    end

    -- Handle settings screen interactions
    if mainMenu.currentScreen == "settings" then
        local screenW = love.graphics.getWidth()
        local centerX = screenW / 2
        local panelWidth = 400
        local panelX = centerX - panelWidth / 2
        local panelY = 120
        
        -- Check for slider interactions
        local sliderY = panelY + 40 + 40 -- Master volume slider Y
        if my >= sliderY and my <= sliderY + mainMenu.audioSettings.sliderHeight * 2 then
            mainMenu.audioSettings.draggingSlider = "master"
            mainMenu.updateSliderValue(mx, panelX + 30, mainMenu.audioSettings.sliderWidth, "master")
        end
        
        sliderY = sliderY + 80 -- Music volume slider Y
        if my >= sliderY and my <= sliderY + mainMenu.audioSettings.sliderHeight * 2 then
            mainMenu.audioSettings.draggingSlider = "music"
            mainMenu.updateSliderValue(mx, panelX + 30, mainMenu.audioSettings.sliderWidth, "music")
        end
        
        sliderY = sliderY + 80 -- SFX volume slider Y
        if my >= sliderY and my <= sliderY + mainMenu.audioSettings.sliderHeight * 2 then
            mainMenu.audioSettings.draggingSlider = "sfx"
            mainMenu.updateSliderValue(mx, panelX + 30, mainMenu.audioSettings.sliderWidth, "sfx")
        end
        
        return
    end
    
    if mainMenu.currentScreen == "modes" then
        local backX, backY = 40, love.graphics.getHeight() - 100
        local buttonWidth, buttonHeight = 160, 50

        if mx > backX and mx < backX + buttonWidth and my > backY and my < backY + buttonHeight then
            mainMenu.currentScreen = "main"
            return
        end

        local modes = gameModes.getAllModes()
        local centerX = love.graphics.getWidth() / 2
        local startY = 150

        for i, mode in ipairs(modes) do
            local buttonX = centerX - mainMenu.buttonWidth / 2
            local buttonY = startY + (i-1) * (mainMenu.buttonHeight + mainMenu.buttonSpacing)

            if mx > buttonX and mx < buttonX + mainMenu.buttonWidth and my > buttonY and my < buttonY + mainMenu.buttonHeight then
                gameModes.setModeById(mode.id)
                mainMenu.currentScreen = "main"
                return
            end
        end
    end

    if mainMenu.currentScreen == "main" then
        local screenW = love.graphics.getWidth()
        local baseY = love.graphics.getHeight() / 2 - (#mainMenu.mainOptions * (mainMenu.buttonHeight + mainMenu.buttonSpacing)) / 2
        local rightX = screenW - mainMenu.buttonWidth - 40
        local leftX = 40

        for i, option in ipairs(mainMenu.mainOptions) do
            local y = baseY + (i-1)*(mainMenu.buttonHeight + mainMenu.buttonSpacing)
            if mx > rightX and mx < rightX + mainMenu.buttonWidth and my > y and my < y + mainMenu.buttonHeight then
                if option.action == "play" then
                    mainMenu.startGame()
                elseif option.action == "modes" then
                    mainMenu.currentScreen = "modes"
                elseif option.action == "exit" then
                    love.event.quit()
                end
                return
            end
        end

        for i, option in ipairs(mainMenu.sideOptions) do
            local y = baseY + (#mainMenu.mainOptions)*(mainMenu.buttonHeight + mainMenu.buttonSpacing) - i*(mainMenu.buttonHeight + mainMenu.buttonSpacing)
            if mx > leftX and mx < leftX + mainMenu.buttonWidth and my > y and my < y + mainMenu.buttonHeight then
                if option.action == "settings" then
                    mainMenu.currentScreen = "settings"
                elseif option.action == "credits" then
                    mainMenu.currentScreen = "credits"
                end
                return
            end
        end
    end
end

function mainMenu.keypressed(key)
    if not mainMenu.active then return end

    if key == "escape" then
        if mainMenu.currentScreen == "modes" or mainMenu.currentScreen == "settings" or mainMenu.currentScreen == "credits" then
            mainMenu.currentScreen = "main"
        end
    end
    
    if mainMenu.currentScreen == "main" then
        mainMenu.handleMainMenuKeypress(key)
    elseif mainMenu.currentScreen == "modes" then
        mainMenu.handleModesMenuKeypress(key)
    end
end

function mainMenu.handleMainMenuKeypress(key)
    if key == "up" or key == "w" then
        mainMenu.selectedOption = math.max(1, mainMenu.selectedOption - 1)
    elseif key == "down" or key == "s" then
        mainMenu.selectedOption = math.min(#mainMenu.mainOptions, mainMenu.selectedOption + 1)
    elseif key == "return" or key == "space" then

        local option = mainMenu.mainOptions[mainMenu.selectedOption]
        if option.action == "play" then
            mainMenu.startGame()
        elseif option.action == "modes" then
            mainMenu.currentScreen = "modes"
            mainMenu.modeSelectionIndex = 1
        elseif option.action == "exit" then
            love.event.quit()
        end
    end
end

function mainMenu.handleModesMenuKeypress(key)
    local modes = gameModes.getAllModes()

    if key == "up" or key == "w" then
        mainMenu.modeSelectionIndex = math.max(1, mainMenu.modeSelectionIndex - 1)
    elseif key == "down" or key == "s" then
        mainMenu.modeSelectionIndex = math.min(#modes, mainMenu.modeSelectionIndex + 1)
    elseif key == "return" or key == "space" then

        gameModes.setModeById(modes[mainMenu.modeSelectionIndex].id)

        mainMenu.currentScreen = "main"
    elseif key == "escape" then

        mainMenu.currentScreen = "main"
    end
end

-- Hide the menu when Play is selected, but don't start the game yet
function mainMenu.startGame()
    mainMenu.transitionState = "out"
    mainMenu.transitionTimer = 0
    
    -- Instead of immediately starting the game, set up a flag that indicates
    -- the player needs to approach the engine and press 'e'
    mainMenu.gameReadyToStart = true
    mainMenu.hide()
    
    -- We'll now rely on the game logic to check if player is near engine
    -- and wait for 'e' key press before starting the actual loading process
end

-- This function will be called by the game when player is near engine and presses 'e'
function mainMenu.actuallyStartGame()
    if mainMenu.gameReadyToStart then
        local loadingBar = require("modules.game.loadingBar")
        -- Reset loading bar and activate it
        loadingBar.reset()
        loadingBar.activate()
        mainMenu.gameReadyToStart = false
    end
end

-- Update slider values based on mouse position
function mainMenu.updateSliderValue(mx, sliderX, sliderWidth, type)
    local value = math.max(0, math.min(1, (mx - sliderX) / sliderWidth))
    
    if type == "master" then
        mainMenu.audioSettings.masterVolume = value
        -- Apply master volume
        local volume = require("modules.init").getVolume()
        volume.master = value
        require("modules.init").applyVolumeSettings()
    elseif type == "music" then
        mainMenu.audioSettings.musicVolume = value
        -- Apply music volume
        local volume = require("modules.init").getVolume()
        volume.music = value
        require("modules.init").applyVolumeSettings()
    elseif type == "sfx" then
        mainMenu.audioSettings.sfxVolume = value
        -- Apply SFX volume
        local volume = require("modules.init").getVolume()
        volume.sfx = value
        require("modules.init").applyVolumeSettings()
    end
end

-- Add mouse moved handler for sliders
function mainMenu.mousemoved(x, y)
    if not mainMenu.active then return end
    
    if mainMenu.audioSettings.draggingSlider then
        local screenW = love.graphics.getWidth()
        local centerX = screenW / 2
        local panelWidth = 400
        local panelX = centerX - panelWidth / 2
        
        mainMenu.updateSliderValue(x, panelX + 30, mainMenu.audioSettings.sliderWidth, mainMenu.audioSettings.draggingSlider)
    end
end

-- Handle mouse release for sliders
function mainMenu.mousereleased(x, y, button)
    if mainMenu.audioSettings.draggingSlider then
        mainMenu.audioSettings.draggingSlider = nil
    end
end

function mainMenu.show()
    mainMenu.transitionState = "in"
    mainMenu.transitionTimer = 0
    mainMenu.active = true
    mainMenu.currentScreen = "main"
    if Background and Background.setMode then

    end
end

-- Hide the menu UI
function mainMenu.hide()
    mainMenu.active = false
end

function mainMenu.isActive()
    return mainMenu.active
end

return mainMenu