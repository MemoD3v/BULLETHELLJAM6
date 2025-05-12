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

    -- Calculate transition progress (0 to 1)
    local transitionProgress = mainMenu.transitionTimer / mainMenu.transitionDuration
    local alpha = 1.0
    
    if mainMenu.transitionState == "out" then
        alpha = 1.0 - transitionProgress
    end

    local flicker = 0.95 + 0.05 * math.sin(mainMenu.animTimer * 40)
    love.graphics.setColor(0, 0, 0, flicker * alpha)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    -- Apply transition effect (slide down)
    love.graphics.push()
    if mainMenu.transitionState == "out" then
        local offsetY = transitionProgress * love.graphics.getHeight() * 0.2
        love.graphics.translate(0, offsetY)
        love.graphics.setColor(1, 1, 1, alpha * 0.8)
    end

    mainMenu.drawGlitchPolygon()

    if mainMenu.currentScreen == "main" then
        mainMenu.drawMainScreen()
    elseif mainMenu.currentScreen == "modes" then
        mainMenu.drawModesScreen()
    end
    
    love.graphics.pop()
end

function mainMenu.drawGlitchPolygon()
    local cx, cy = love.graphics.getWidth()/2, love.graphics.getHeight()/2
    local sides = 6
    local radius = 100 + 20 * math.sin(mainMenu.animTimer * 3)
    local vertices = {}
    for i = 1, sides do
        local angle = (i / sides) * math.pi * 2 + mainMenu.animTimer * 0.8
        local r = radius + math.random(-20, 20)
        table.insert(vertices, cx + math.cos(angle) * r)
        table.insert(vertices, cy + math.sin(angle) * r)
    end
    love.graphics.setColor(1, 0.1 + math.random() * 0.2, 0.3, 0.3 + math.random() * 0.4)
    love.graphics.polygon("fill", vertices)
    love.graphics.setColor(1, 1, 1, 0.1 + math.random() * 0.4)
    love.graphics.polygon("line", vertices)
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

function mainMenu.mousepressed(x, y, button)
    if not mainMenu.active or button ~= 1 then return end
    local mx, my = x, y

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
                print("Selected: " .. option.text .. " (not implemented)")
                return
            end
        end
    end
end

function mainMenu.keypressed(key)
    if not mainMenu.active then return end

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

function mainMenu.startGame()
    mainMenu.transitionState = "out"
    mainMenu.transitionTimer = 0
end

function mainMenu.show()
    mainMenu.transitionState = "in"
    mainMenu.transitionTimer = 0
    mainMenu.active = true
    mainMenu.currentScreen = "main"
    if Background and Background.setMode then

    end
end
function mainMenu.isActive()
    return mainMenu.active
end

return mainMenu