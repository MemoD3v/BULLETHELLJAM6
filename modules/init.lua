local game = {}

-- Import all modules
local config = require("modules.game.config")
local camera = require("modules.game.camera")
local player = require("modules.game.player")
local bullets = require("modules.game.bullets")
local enemies = require("modules.game.enemies")
local loadingBar = require("modules.game.loadingBar")
local engine = require("modules.game.engine")
local ui = require("modules.game.ui")
local gameState = require("modules.game.gameState")
local enemyBullets = require("modules.game.enemyBullets")
local powerUps = require("modules.game.powerUps")
local healingOrbs = require("modules.game.healingOrbs") -- New healing orbs module
local gameModes = require("modules.game.gameModes")
local mainMenu = require("modules.game.mainMenu")
local bg = require("modules.game.background")

-- Grid positioning
local gridOffsetX, gridOffsetY = 0, 0

-- Fonts
local fonts = {
    small = nil,
    medium = nil,  -- Added medium font
    large = nil,
    extraLarge = nil,
    massive = nil
}

-- Game sounds
local sounds = {
    musicBeforeStart = nil,    -- Before payload starts
    musicAfterStart = nil,     -- After payload starts
    powerUp = nil,             -- Power-up acquired
    powerUpSpawn = nil,        -- Power-up or healing orb spawned
    heal = nil,                -- Healing effect
    enemyDeath = nil,          -- Enemy death
    enemyShoot = nil,          -- Enemy shooting
    checkpoint = nil,          -- Checkpoint reached
    playerDeath = nil,         -- Player or engine death
    playerHurt = nil,          -- Player damage
    playerShoot = nil,         -- Player shoot
    phaseComplete = nil,       -- Phase completed
    damage = nil               -- Damage to payload/loading bar
}

-- Volume controls
local volume = {
    master = 0.8,  -- 0.0 to 1.0
    music = 0.7,   -- relative to master
    sfx = 1.0      -- relative to master
}

-- Canvas for capturing the game screen to display on the cheat engine
local gameCanvas = nil

function game.load()
    local ww, wh = love.graphics.getDimensions()
    bg.init()
    gridOffsetX = (ww - config.gridSize * config.cellSize) / 2
    gridOffsetY = (wh - config.gridSize * config.cellSize) / 2 + 40
    
    -- Initialize the game canvas for the cheat engine mini-display
    -- Using a smaller resolution for the mini-display
    gameCanvas = love.graphics.newCanvas(ww, wh)

    -- Load fonts
    fonts.small = love.graphics.newFont("source/fonts/Jersey10.ttf", 16)
    fonts.medium = love.graphics.newFont("source/fonts/Jersey10.ttf", 20)  -- Initialize medium font
    fonts.large = love.graphics.newFont("source/fonts/Jersey10.ttf", 24)
    fonts.extraLarge = love.graphics.newFont("source/fonts/Jersey10.ttf", 36)
    fonts.massive = love.graphics.newFont("source/fonts/Jersey10.ttf", 48)
    
    loadingBar.font = fonts.large
    
    -- Load sound effects
    sounds.musicBeforeStart = love.audio.newSource("source/sfx/Before-Start {{ Glitch in the Grid.mp3", "stream")
    sounds.musicAfterStart = love.audio.newSource("source/sfx/After-Start }} Glitch in My Veins.mp3", "stream")
    sounds.powerUp = love.audio.newSource("source/sfx/PowerUp.wav", "static")
    sounds.powerUpSpawn = love.audio.newSource("source/sfx/checkpoint.wav", "static") -- Reuse checkpoint sound
    sounds.heal = love.audio.newSource("source/sfx/PowerUp.wav", "static") -- Reuse powerup sound for healing
    sounds.enemyDeath = love.audio.newSource("source/sfx/bad person ded.wav", "static")
    sounds.enemyShoot = love.audio.newSource("source/sfx/bad pew pew pew.wav", "static")
    sounds.checkpoint = love.audio.newSource("source/sfx/checkpoint.wav", "static")
    sounds.playerDeath = love.audio.newSource("source/sfx/ded player- ded engine.wav", "static")
    sounds.playerHurt = love.audio.newSource("source/sfx/hurt.wav", "static")
    sounds.playerShoot = love.audio.newSource("source/sfx/pew-pew-pew.wav", "static")
    sounds.phaseComplete = love.audio.newSource("source/sfx/phasedone.wav", "static")
    sounds.damage = love.audio.newSource("source/sfx/hurt.wav", "static") -- Reusing hurt sound for damage to payload
    
    -- Set loop property for music
    sounds.musicBeforeStart:setLooping(true)
    sounds.musicAfterStart:setLooping(true)
    
    -- Apply volume settings to all sounds
    game.applyVolumeSettings()
    
    -- Initialize game modes
    gameModes.init()
    
    -- Initialize modules with safety checks
    if player and player.init then player.init() end
    if bullets and bullets.init then bullets.init() end
    if enemies and enemies.init then enemies.init() end
    if enemyBullets and enemyBullets.init then enemyBullets.init() end
    if loadingBar and loadingBar.init then loadingBar.init() end
    if powerUps and powerUps.init then powerUps.init(gridOffsetX, gridOffsetY) end
    
    -- Initialize healing orbs (make sure this happens after all other modules)
    if healingOrbs and healingOrbs.init then
        healingOrbs.init()
    end
    
    -- Initialize main menu
    mainMenu.init(fonts)
    mainMenu.show() -- Show the main menu when the game starts
    
    -- Start the initial music
    sounds.musicBeforeStart:play()
end

-- Add function to start a new game with the current game mode
-- Reset all game components to their initial state
function game.reset()
    -- Reset game state (score, timer, etc.)
    gameState.reset()
    
    bg.active = false

    -- Reset modules with safety checks
    if player and player.reset then player.reset() end
    if bullets and bullets.reset then bullets.reset() end
    if enemies and enemies.reset then enemies.reset() end
    if enemyBullets and enemyBullets.reset then enemyBullets.reset() end
    if engine and engine.reset then engine.reset() end
    if camera and camera.reset then camera.reset() end
    if loadingBar and loadingBar.reset then loadingBar.reset() end
    if powerUps and powerUps.reset then powerUps.reset() end
    
    -- Reset healing orbs safely
    if healingOrbs and healingOrbs.reset then
        healingOrbs.reset()
    end
    
    -- Setup new game with the current game mode
    local enemySpawnMultiplier = gameModes.getEnemySpawnMultiplier()
    enemies.setSpawnRate(enemies.baseSpawnRate / enemySpawnMultiplier)
    
    -- Start loading bar for all modes except endless
    loadingBar.active = gameModes.hasEndCondition()
 end

function game.startGame()
    -- Reset all game components
    game.reset()
    
    -- Set player health based on game mode
    local startingHealth = gameModes.getStartingHealth()
    player.setMaxHealth(startingHealth)
    player.setHealth(startingHealth)
    
    -- Hide the main menu
    mainMenu.active = false
    
    -- Start the music if it's not playing
    if not sounds.musicBeforeStart:isPlaying() then
        sounds.musicBeforeStart:play()
    end
 end

function game.update(dt)
    bg.update(dt)
    
    -- Update main menu if active
    if mainMenu.isActive() then
        mainMenu.update(dt)
        return
    end
    
    if gameState.isGameOver() then 
        -- Check if in Endless mode and handle returning to menu on game over
        if not gameModes.hasEndCondition() and love.keyboard.isDown("r") then
            mainMenu.show()
            return
        end
        return 
    end
    
    -- Don't update game mechanics when paused, but still update visual effects
    if gameState.isPaused() then
        gameState.update(dt)
        return
    end
    
    -- Don't update anything else if typing power-up code
    if powerUps.showTypingInterface then
        powerUps.update(dt, loadingBar.absoluteCheckpoint)
        return
    end

    -- Update loading bar and checkpoints
    local prevCheckpoint = loadingBar.currentCheckpoint
    loadingBar.update(dt)
    
    -- Check if we reached a new checkpoint to offer a power-up
    if loadingBar.active and loadingBar.currentCheckpoint > prevCheckpoint then
        powerUps.showSelectionAt(loadingBar.absoluteCheckpoint)
    end
    
    -- Calculate camera shake based on engine activity and enemies
    if loadingBar.active then
        local baseShake = 0.5 + loadingBar.progress * 3
        
        local dangerShake = 0
        local engineX = gridOffsetX + (engine.x - 1) * config.cellSize + config.cellSize / 2
        local engineY = gridOffsetY + (engine.y - 1) * config.cellSize + config.cellSize / 2
        
        for _, e in ipairs(enemies.list) do
            local dist = math.sqrt((e.x - engineX)^2 + (e.y - engineY)^2)
            if dist < 200 then
                dangerShake = dangerShake + (200 - dist)/200 * 2
            end
        end
        
        camera.shake(baseShake + dangerShake, 0.5)
    end
    
    -- Update camera shake
    camera.update(dt, engine.instabilityLevel)
    
    -- Update player movement
    player.update(dt, config.gridSize, gridOffsetX, gridOffsetY)
    
    -- Update engine animation and state
    engine.update(dt, loadingBar.currentCheckpoint, player.x, player.y)
    
    -- Update bullets
    bullets.update(dt)
    
    -- Update enemies
    enemies.update(dt, gridOffsetX, gridOffsetY, loadingBar.active)
    
    -- Update enemy bullets
    enemyBullets.update(dt)
    
    -- Update power-ups
    powerUps.update(dt, gameState.absoluteCheckpoint)
    
    -- Update healing orbs
    healingOrbs.update(dt, gridOffsetX, gridOffsetY) -- Update healing orbs
    
    -- Update game state
    gameState.update(dt)
    
    -- Update UI elements based on player status
    ui.updatePlayerStatus(player.getHealth())
end

function game.draw()
    bg.draw()

    -- Draw main menu if active
    if mainMenu.isActive() then
        mainMenu.draw()
        return
    end
    
    -- If showing power-up typing interface, only draw that
    if powerUps.showTypingInterface then
        powerUps.draw(fonts)
        return
    end
    
    -- Capture the current game state to the canvas for the mini-display
    -- This must be done in a way that doesn't affect the main rendering
    if gameCanvas then
        -- Only capture if we're actively playing (not paused or game over)
        if not gameState.isPaused() and not gameState.isGameOver() then
            -- First, save everything about the current graphics state
            local prevCanvas = love.graphics.getCanvas()
            local r, g, b, a = love.graphics.getColor()
            
            -- Switch to our capture canvas
            love.graphics.setCanvas(gameCanvas)
            love.graphics.clear(0, 0, 0, 1) -- Clear with black background
            love.graphics.setColor(1, 1, 1, 1) -- Full white for proper colors
            
            -- Draw a small version of the game world to the canvas
            ui.drawGrid(gridOffsetX, gridOffsetY, config.gridSize, config.cellSize, config.gridColor)
            enemies.draw(fonts, engine.instabilityLevel)
            bullets.draw(gridOffsetX, gridOffsetY)
            enemyBullets.draw(gridOffsetX, gridOffsetY)
            healingOrbs.draw() -- Draw healing orbs
            player.draw(gridOffsetX, gridOffsetY, fonts)
            
            -- Important: Switch back to the previous canvas (usually the main screen)
            love.graphics.setCanvas(prevCanvas)
            
            -- Restore previous color state
            love.graphics.setColor(r, g, b, a)
        end
    end

    -- Apply camera shake
    love.graphics.push()
    local shakeX, shakeY = camera.getOffset()
    love.graphics.translate(shakeX, shakeY)
    
    -- Draw grid
    ui.drawGrid(gridOffsetX, gridOffsetY, config.gridSize, config.cellSize, config.gridColor)
    
    -- Draw loading bar
    loadingBar.draw(gridOffsetX, gridOffsetY, fonts)
    
    -- Draw engine
    local showPrompt = not loadingBar.active and engine.isPlayerNearby(player.x, player.y)
    engine.draw(gridOffsetX, gridOffsetY, fonts, showPrompt)
    
    -- Draw enemies (this will also draw enemy bullets)
    enemies.draw(fonts, engine.instabilityLevel)
    
    -- Draw player
    player.draw(gridOffsetX, gridOffsetY, fonts)
    
    -- Draw player bullets
    bullets.draw()
    
    -- Draw healing orbs
    healingOrbs.draw(gridOffsetX, gridOffsetY)
    
    -- Draw score and game status
    ui.drawScore(gameState.getScore(), fonts.small)
    ui.drawPlayerStatus(fonts.small)
    
    -- Draw passive nuke UI (always visible in all game modes)
    ui.drawPassiveNuke(fonts.small)
    
    -- Draw power-ups
    powerUps.draw(fonts)
    
    -- Draw game over screen if needed
    if gameState.isGameOver() then
        ui.drawGameOver(gameState.getScore(), fonts)
    end
    
    -- Draw pause overlay if paused
    if gameState.isPaused() then
        gameState.drawPauseOverlay(fonts)
    end
    
    -- Draw volume display if active
    ui.drawVolumeDisplay(fonts.small, volume)
    
    love.graphics.pop()
    
    -- Draw instructions screen (this is drawn on top of everything else)
    -- and is not affected by camera shake
    if ui.instructionsActive then
        ui.drawInstructions(fonts)
    end
end

function game.keypressed(key)
    -- Check if main menu is active
    if mainMenu.isActive() then
        mainMenu.keypressed(key)
        
        -- Check if the menu wants to start the game
        if key == "return" and mainMenu.currentScreen == "main" and mainMenu.selectedOption == 1 then
            -- Start game with current mode
            game.startGame()
        end
        return
    end

    -- Handle the 'M' key to return to main menu (works both during gameplay and on game over screen)
    if key == "m" then
        -- Only allow returning to menu if game is paused, finished, or if ESC was pressed first
        if gameState.isGameOver() or gameState.isPaused() then
            mainMenu.show()
            return
        end
    end
    
    -- First check if instructions are active and dismiss them
    if ui.instructionsActive then
        ui.dismissInstructions()
        return
    end
    
    -- Handle power-up typing interface keypresses
    if powerUps.showTypingInterface then
        powerUps.keypressed(key)
        return
    end

    -- Handle game reset
    if gameState.isGameOver() and key == "r" then
        game.reset()
        return
    end
    
    -- Handle escape to pause/unpause (consolidated from duplicate code)
    if key == "escape" then
        gameState.togglePause()
        return
    end
    
    -- Engine activation with 'e' key
    if key == "e" and not loadingBar.active and not gameState.isGameOver() then
        if engine.isPlayerNearby(player.x, player.y) then
            loadingBar.activate()
            bg.activate()
            return
        end
    end
    
    -- Handle player special abilities (nuke, dash, etc.)
    -- Always handle passive nuke (available in all game modes)
    -- For other abilities, only process them when the game is active
    if not gameState.isPaused() and not gameState.isGameOver() then
        player.keypressed(key, enemies.list)
    end
    
    -- Volume control shortcuts (these work regardless of game state)
    if key == "=" or key == "+" then  -- Increase master volume
        game.adjustVolume("master", 0.1)
    elseif key == "-" then  -- Decrease master volume
        game.adjustVolume("master", -0.1)
    elseif key == "[" then  -- Decrease music volume
        game.adjustVolume("music", -0.1)
    elseif key == "]" then  -- Increase music volume
        game.adjustVolume("music", 0.1)
    elseif key == ";" then  -- Decrease SFX volume
        game.adjustVolume("sfx", -0.1)
    elseif key == "'" then  -- Increase SFX volume
        game.adjustVolume("sfx", 0.1)
    end
end

function game.mousepressed(x, y, button)
    -- Debug info
    print("Mouse pressed: button=" .. button .. ", x=" .. x .. ", y=" .. y)
    
    -- Don't process clicks during power-up typing interface
    if powerUps and powerUps.showTypingInterface then 
        print("Skipping mouse input - typing interface active")
        return 
    end
    
    -- Don't process clicks if game is paused or over
    if gameState.isPaused() or gameState.isGameOver() then
        print("Skipping mouse input - game paused or over")
        return
    end
    
    -- COMPLETELY REVISED SHOOTING LOGIC:
    -- Always allow shooting in all game modes
    if button == 1 then  -- Left click = shoot
        print("Attempting to shoot")
        
        -- Create a bullet directly from the bullets module
        local px, py = player.getScreenPosition(gridOffsetX, gridOffsetY)
        local bulletModule = require("modules.game.bullets")
        
        -- Create bullet directly, forcing a fresh reference to the module
        print("Creating bullet from (" .. px .. "," .. py .. ") to (" .. x .. "," .. y .. ")")
        bulletModule.create(px, py, x, y)
    end
end

-- Volume control functions
function game.adjustVolume(volumeType, amount)
    if volumeType == "master" then
        volume.master = math.max(0, math.min(1, volume.master + amount))
        game.applyVolumeSettings()
    elseif volumeType == "music" then
        volume.music = math.max(0, math.min(1, volume.music + amount))
        game.applyVolumeSettings()
    elseif volumeType == "sfx" then
        volume.sfx = math.max(0, math.min(1, volume.sfx + amount))
        game.applyVolumeSettings()
    end
    
    -- Show volume display UI
    ui.showVolumeDisplay()
end

function game.applyVolumeSettings()
    -- Apply to music
    local musicVolume = volume.master * volume.music
    if sounds.musicBeforeStart then sounds.musicBeforeStart:setVolume(musicVolume) end
    if sounds.musicAfterStart then sounds.musicAfterStart:setVolume(musicVolume) end
    
    -- Apply to SFX
    local sfxVolume = volume.master * volume.sfx
    if sounds.powerUp then sounds.powerUp:setVolume(sfxVolume) end
    if sounds.enemyDeath then sounds.enemyDeath:setVolume(sfxVolume) end
    if sounds.enemyShoot then sounds.enemyShoot:setVolume(sfxVolume) end
    if sounds.checkpoint then sounds.checkpoint:setVolume(sfxVolume) end
    if sounds.playerDeath then sounds.playerDeath:setVolume(sfxVolume) end
    if sounds.playerHurt then sounds.playerHurt:setVolume(sfxVolume) end
    if sounds.playerShoot then sounds.playerShoot:setVolume(sfxVolume) end
    if sounds.phaseComplete then sounds.phaseComplete:setVolume(sfxVolume) end
    if sounds.damage then sounds.damage:setVolume(sfxVolume) end
end

-- Get current volume settings
function game.getVolume()
    return volume
end

-- Expose sounds to other modules
function game.getSounds()
    return sounds
end

-- Add getter functions for grid offsets
function game.getGridOffsetX()
    return gridOffsetX
end

function game.getGridOffsetY()
    return gridOffsetY
end

-- Function to get the game canvas for the mini-display
function game.getGameCanvas()
    return gameCanvas
end

function game.reset()
    -- Reset all game components
    player.reset()
    enemies.reset()
    bullets.reset()
    enemyBullets.reset()
    loadingBar.reset()
    engine.reset()
    gameState.reset()
    ui.reset()
    
    -- Safely reset powerUps if the function exists
    if powerUps and type(powerUps.reset) == "function" then
        powerUps.reset()
    else
        -- Manual reset of critical powerUps state if the function isn't available
        if powerUps then
            powerUps.active = nil
            powerUps.showTypingInterface = false
            powerUps.codingInput = ""
            powerUps.codingErrorMsg = ""
            powerUps.codingSuccessTime = 0
            powerUps.wormholeActive = false
            powerUps.crashEffectActive = false
        end
    end
    
    -- Reset music
    sounds.musicAfterStart:stop()
    sounds.musicBeforeStart:play()
end

function game.resize(w, h)
    gridOffsetX = (w - config.gridSize * config.cellSize) / 2
    gridOffsetY = (h - config.gridSize * config.cellSize) / 2 + 40
end

function game.textinput(text)
    -- Forward text input to the power-up system
    if powerUps.showTypingInterface then
        powerUps.textinput(text)
    end
end

return game