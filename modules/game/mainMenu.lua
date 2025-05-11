local mainMenu = {}

local gameModes = require("modules.game.gameModes")

-- Menu state
mainMenu.active = true
mainMenu.currentScreen = "main" -- "main", "modes", "credits"
mainMenu.selectedOption = 1
mainMenu.modeSelectionIndex = 1
mainMenu.animTimer = 0
mainMenu.titleScale = 1.0
mainMenu.buttonHover = nil

-- Menu options
mainMenu.mainOptions = {
    { text = "Play Game", action = "play" },
    { text = "Game Modes", action = "modes" },
    { text = "Exit Game", action = "exit" }
}

-- Button dimensions
mainMenu.buttonWidth = 220
mainMenu.buttonHeight = 50
mainMenu.buttonSpacing = 20

-- Initialize the menu
function mainMenu.init(fonts)
    mainMenu.fonts = fonts
    -- Start with menu active
    mainMenu.active = true
    mainMenu.currentScreen = "main"
    mainMenu.selectedOption = 1
    mainMenu.modeSelectionIndex = 1
    mainMenu.animTimer = 0
    -- Initialize game modes
    gameModes.init()
end

-- Update the menu
function mainMenu.update(dt)
    if not mainMenu.active then return end
    
    -- Update animation timer
    mainMenu.animTimer = mainMenu.animTimer + dt
    
    -- Animate title scale
    mainMenu.titleScale = 1.0 + 0.05 * math.sin(mainMenu.animTimer * 2)
end

-- Draw the menu
function mainMenu.draw()
    if not mainMenu.active then return end
    
    -- Background
    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Draw glitch grid in background
    mainMenu.drawBackgroundGrid()
    
    -- Draw appropriate screen
    if mainMenu.currentScreen == "main" then
        mainMenu.drawMainScreen()
    elseif mainMenu.currentScreen == "modes" then
        mainMenu.drawModesScreen()
    end
end

-- Draw the background grid effect
function mainMenu.drawBackgroundGrid()
    love.graphics.setColor(0.1, 0.2, 0.3, 0.1)
    local gridSize = 40
    for x = 0, love.graphics.getWidth(), gridSize do
        love.graphics.line(x, 0, x, love.graphics.getHeight())
    end
    for y = 0, love.graphics.getHeight(), gridSize do
        love.graphics.line(0, y, love.graphics.getWidth(), y)
    end
    
    -- Draw some random "glitch" rectangles that move
    love.graphics.setColor(0.7, 0.2, 0.3, 0.1)
    for i = 1, 5 do
        local xPos = (love.graphics.getWidth() * 0.5) + 200 * math.sin(mainMenu.animTimer * 0.5 + i)
        local yPos = (love.graphics.getHeight() * 0.5) + 200 * math.cos(mainMenu.animTimer * 0.3 + i)
        love.graphics.rectangle("fill", xPos, yPos, 100, 20)
    end
end

-- Draw the main menu screen
function mainMenu.drawMainScreen()
    local centerX = love.graphics.getWidth() / 2
    local centerY = love.graphics.getHeight() / 2 - 100
    
    -- Draw title
    love.graphics.setFont(mainMenu.fonts.massive)
    love.graphics.setColor(0.8, 0.2, 0.2)
    local titleText = "GLITCH IN THE GRID"
    local titleWidth = mainMenu.fonts.massive:getWidth(titleText)
    
    -- Draw title with scaling animation
    love.graphics.push()
    love.graphics.translate(centerX, centerY - 50)
    love.graphics.scale(mainMenu.titleScale, mainMenu.titleScale)
    love.graphics.print(titleText, -titleWidth/2, 0)
    love.graphics.pop()
    
    -- Draw selected game mode 
    love.graphics.setFont(mainMenu.fonts.small)
    love.graphics.setColor(0.8, 0.8, 0.8, 0.8)
    local currentMode = gameModes.getCurrentMode()
    local modeText = "Mode: " .. currentMode.name
    local modeDesc = currentMode.description
    local modeWidth = mainMenu.fonts.small:getWidth(modeText)
    love.graphics.print(modeText, centerX - modeWidth/2, centerY + 20)
    
    local descWidth = mainMenu.fonts.small:getWidth(modeDesc)
    love.graphics.setColor(0.8, 0.8, 0.8, 0.6)
    love.graphics.print(modeDesc, centerX - descWidth/2, centerY + 40)
    
    -- Draw menu options
    love.graphics.setFont(mainMenu.fonts.large)
    local startY = centerY + 100
    
    for i, option in ipairs(mainMenu.mainOptions) do
        local buttonX = centerX - mainMenu.buttonWidth / 2
        local buttonY = startY + (i-1) * (mainMenu.buttonHeight + mainMenu.buttonSpacing)
        
        -- Button background
        local isHovered = (i == mainMenu.selectedOption)
        if isHovered then
            love.graphics.setColor(0.3, 0.6, 0.9, 0.7)
        else
            love.graphics.setColor(0.2, 0.2, 0.3, 0.7)
        end
        
        -- Draw button with a slight animation for the selected one
        if isHovered then
            local pulse = 5 * math.sin(mainMenu.animTimer * 5)
            love.graphics.rectangle("fill", buttonX - pulse/2, buttonY, mainMenu.buttonWidth + pulse, mainMenu.buttonHeight, 8, 8)
            -- Button border
            love.graphics.setColor(0.5, 0.8, 1.0, 0.8)
            love.graphics.rectangle("line", buttonX - pulse/2, buttonY, mainMenu.buttonWidth + pulse, mainMenu.buttonHeight, 8, 8)
        else
            love.graphics.rectangle("fill", buttonX, buttonY, mainMenu.buttonWidth, mainMenu.buttonHeight, 8, 8)
        end
        
        -- Button text
        if isHovered then
            love.graphics.setColor(1, 1, 1, 1)
        else
            love.graphics.setColor(0.8, 0.8, 0.8, 0.8)
        end
        
        local textWidth = mainMenu.fonts.large:getWidth(option.text)
        love.graphics.print(option.text, centerX - textWidth/2, buttonY + mainMenu.buttonHeight/2 - mainMenu.fonts.large:getHeight()/2)
    end
    
    -- Draw instructions
    love.graphics.setFont(mainMenu.fonts.small)
    love.graphics.setColor(0.7, 0.7, 0.7, 0.7)
    local instructionsText = "Arrow Keys: Navigate   Enter: Select"
    local instructionsWidth = mainMenu.fonts.small:getWidth(instructionsText)
    love.graphics.print(instructionsText, centerX - instructionsWidth/2, love.graphics.getHeight() - 40)
end

-- Draw the game modes selection screen
function mainMenu.drawModesScreen()
    local centerX = love.graphics.getWidth() / 2
    -- Moved centerY higher to prevent button overlap
    local centerY = love.graphics.getHeight() / 4
    
    -- Draw title
    love.graphics.setFont(mainMenu.fonts.extraLarge)
    love.graphics.setColor(0.8, 0.2, 0.2)
    local titleText = "GAME MODES"
    local titleWidth = mainMenu.fonts.extraLarge:getWidth(titleText)
    love.graphics.print(titleText, centerX - titleWidth/2, centerY - 80)
    
    -- Draw mode options
    local modes = gameModes.getAllModes()
    local startY = centerY
    
    love.graphics.setFont(mainMenu.fonts.large)
    
    for i, mode in ipairs(modes) do
        local buttonX = centerX - mainMenu.buttonWidth / 2
        local buttonY = startY + (i-1) * (mainMenu.buttonHeight + mainMenu.buttonSpacing)
        
        -- Button background
        local isSelected = (i == mainMenu.modeSelectionIndex)
        if isSelected then
            love.graphics.setColor(0.3, 0.6, 0.9, 0.7)
        else
            love.graphics.setColor(0.2, 0.2, 0.3, 0.7)
        end
        
        -- Draw button with a slight animation for the selected one
        if isSelected then
            local pulse = 5 * math.sin(mainMenu.animTimer * 5)
            love.graphics.rectangle("fill", buttonX - pulse/2, buttonY, mainMenu.buttonWidth + pulse, mainMenu.buttonHeight, 8, 8)
            -- Button border
            love.graphics.setColor(0.5, 0.8, 1.0, 0.8)
            love.graphics.rectangle("line", buttonX - pulse/2, buttonY, mainMenu.buttonWidth + pulse, mainMenu.buttonHeight, 8, 8)
        else
            love.graphics.rectangle("fill", buttonX, buttonY, mainMenu.buttonWidth, mainMenu.buttonHeight, 8, 8)
        end
        
        -- Button text
        if isSelected then
            love.graphics.setColor(1, 1, 1, 1)
        else
            love.graphics.setColor(0.8, 0.8, 0.8, 0.8)
        end
        
        local textWidth = mainMenu.fonts.large:getWidth(mode.name)
        love.graphics.print(mode.name, centerX - textWidth/2, buttonY + mainMenu.buttonHeight/2 - mainMenu.fonts.large:getHeight()/2)
    end
    
    -- Draw mode description
    if mainMenu.modeSelectionIndex <= #modes then
        local selectedMode = modes[mainMenu.modeSelectionIndex]
        love.graphics.setFont(mainMenu.fonts.small)
        love.graphics.setColor(0.8, 0.8, 0.8, 0.9)
        
        -- Create a description panel on the far left side of the screen to avoid button overlap completely
        local descriptionPanelX = 20 -- Move much further to the left
        local descriptionPanelY = startY
        local descriptionPanelWidth = 200 -- Make the panel even narrower
        
        -- Calculate button positions to ensure we avoid overlap
        local buttonX = centerX - mainMenu.buttonWidth / 2
        local buttonLeftEdge = buttonX - 40 -- Add some margin
        local descriptionRightEdge = descriptionPanelX + descriptionPanelWidth + 20 -- Panel width + margin
        
        -- Ensure no overlap with buttons
        if descriptionRightEdge > buttonLeftEdge then
            descriptionPanelWidth = buttonLeftEdge - descriptionPanelX - 40 -- Force no overlap with extra margin
        end
        
        -- Draw a semi-transparent background for the description panel
        love.graphics.setColor(0.1, 0.1, 0.2, 0.7)
        love.graphics.rectangle("fill", descriptionPanelX - 10, descriptionPanelY - 10, 
                             descriptionPanelWidth + 20, 300, 8, 8)
        love.graphics.setColor(0.3, 0.3, 0.5, 0.5)
        love.graphics.rectangle("line", descriptionPanelX - 10, descriptionPanelY - 10, 
                             descriptionPanelWidth + 20, 300, 8, 8)
                             
        -- Draw description header
        love.graphics.setColor(1, 0.8, 0.2, 0.9)
        love.graphics.print("Description:", descriptionPanelX, descriptionPanelY)
        
        -- Draw description text
        love.graphics.setColor(0.9, 0.9, 0.9, 0.8)
        love.graphics.printf(selectedMode.description, descriptionPanelX, descriptionPanelY + 25, descriptionPanelWidth, "left")
        
        -- Draw mode stats
        local statsY = descriptionPanelY + 80 -- Position stats below the description text
        love.graphics.setColor(0.7, 0.9, 1.0, 0.8)
        love.graphics.print("Starting Health: " .. selectedMode.startingHealth, descriptionPanelX, statsY)
        love.graphics.print("Enemy Spawn Rate: " .. selectedMode.enemySpawnMultiplier .. "x", descriptionPanelX, statsY + 25)
        love.graphics.print("Score Multiplier: " .. selectedMode.scoreMultiplier .. "x", descriptionPanelX, statsY + 50)
        
        -- Show special features
        local specialY = statsY + 85
        if selectedMode.vampiricEffect then
            love.graphics.setColor(0.9, 0.3, 0.3, 0.9)
            love.graphics.print("SPECIAL: Gain " .. selectedMode.healthPerKill .. " health per enemy kill", descriptionPanelX, specialY)
            specialY = specialY + 25
        end
        
        if not selectedMode.hasEndCondition then
            love.graphics.setColor(0.3, 0.9, 0.3, 0.9)
            love.graphics.print("SPECIAL: Endless mode - no victory condition", descriptionPanelX, specialY)
        end
    end
    
    -- Back button removed - users can press ESC to go back
    
    -- Draw instructions
    love.graphics.setFont(mainMenu.fonts.small)
    love.graphics.setColor(0.7, 0.7, 0.7, 0.7)
    local instructionsText = "Arrow Keys: Navigate   Enter: Select   ESC: Back"
    local instructionsWidth = mainMenu.fonts.small:getWidth(instructionsText)
    love.graphics.print(instructionsText, centerX - instructionsWidth/2, love.graphics.getHeight() - 40)
end

-- Handle keypresses in the menu
function mainMenu.keypressed(key)
    if not mainMenu.active then return end
    
    if mainMenu.currentScreen == "main" then
        mainMenu.handleMainMenuKeypress(key)
    elseif mainMenu.currentScreen == "modes" then
        mainMenu.handleModesMenuKeypress(key)
    end
end

-- Handle keypresses in the main menu
function mainMenu.handleMainMenuKeypress(key)
    if key == "up" or key == "w" then
        mainMenu.selectedOption = math.max(1, mainMenu.selectedOption - 1)
    elseif key == "down" or key == "s" then
        mainMenu.selectedOption = math.min(#mainMenu.mainOptions, mainMenu.selectedOption + 1)
    elseif key == "return" or key == "space" then
        -- Execute the selected option
        local option = mainMenu.mainOptions[mainMenu.selectedOption]
        if option.action == "play" then
            -- Start the game with the current game mode
            mainMenu.startGame()
        elseif option.action == "modes" then
            -- Switch to the modes screen
            mainMenu.currentScreen = "modes"
            mainMenu.modeSelectionIndex = 1
        elseif option.action == "exit" then
            -- Exit the game
            love.event.quit()
        end
    end
end

-- Handle keypresses in the modes menu
function mainMenu.handleModesMenuKeypress(key)
    local modes = gameModes.getAllModes()
    
    if key == "up" or key == "w" then
        mainMenu.modeSelectionIndex = math.max(1, mainMenu.modeSelectionIndex - 1)
    elseif key == "down" or key == "s" then
        mainMenu.modeSelectionIndex = math.min(#modes, mainMenu.modeSelectionIndex + 1)
    elseif key == "return" or key == "space" then
        -- Select the game mode
        gameModes.setModeById(modes[mainMenu.modeSelectionIndex].id)
        -- Return to main menu
        mainMenu.currentScreen = "main"
    elseif key == "escape" then
        -- Return to main menu
        mainMenu.currentScreen = "main"
    end
end

-- Start the game
function mainMenu.startGame()
    mainMenu.active = false
    -- The game should be initialized and started from the init.lua file
end

-- Show the menu (can be called to return to menu from the game)
function mainMenu.show()
    mainMenu.active = true
    mainMenu.currentScreen = "main"
    mainMenu.selectedOption = 1
end

-- Is the menu currently active?
function mainMenu.isActive()
    return mainMenu.active
end

return mainMenu
