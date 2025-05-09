local game = {}

-- Import all modules
local config = require("modules.game.config")
local player = require("modules.game.player")
local bullets = require("modules.game.bullets")
local enemies = require("modules.game.enemies")
local engine = require("modules.game.engine")
local loadingBar = require("modules.game.loadingBar")
local camera = require("modules.game.camera")
local ui = require("modules.game.ui")
local gameState = require("modules.game.gameState")
local enemyBullets = require("modules.game.enemyBullets")
local powerUps = require("modules.game.powerUps")

-- Grid positioning
local gridOffsetX, gridOffsetY = 0, 0

-- Fonts
local fonts = {
    small = nil,
    large = nil,
    extraLarge = nil,
    massive = nil
}

-- Game sounds
local sounds = {
    musicBeforeStart = nil,    -- Before payload starts
    musicAfterStart = nil,     -- After payload starts
    powerUp = nil,             -- Power-up acquired
    enemyDeath = nil,          -- Enemy death
    enemyShoot = nil,          -- Enemy shooting
    checkpoint = nil,          -- Checkpoint reached
    playerDeath = nil,         -- Player or engine death
    playerHurt = nil,          -- Player damage
    playerShoot = nil,         -- Player shoot
    phaseComplete = nil        -- Phase completed
}

-- Volume controls
local volume = {
    master = 0.8,  -- 0.0 to 1.0
    music = 0.7,   -- relative to master
    sfx = 1.0      -- relative to master
}

function game.load()
    local ww, wh = love.graphics.getDimensions()
    gridOffsetX = (ww - config.gridSize * config.cellSize) / 2
    gridOffsetY = (wh - config.gridSize * config.cellSize) / 2 + 40

    -- Load fonts
    fonts.small = love.graphics.newFont("source/fonts/Jersey10.ttf", 16)
    fonts.large = love.graphics.newFont("source/fonts/Jersey10.ttf", 24)
    fonts.extraLarge = love.graphics.newFont("source/fonts/Jersey10.ttf", 36)
    fonts.massive = love.graphics.newFont("source/fonts/Jersey10.ttf", 48)
    
    loadingBar.font = fonts.large
    
    -- Load sound effects
    sounds.musicBeforeStart = love.audio.newSource("source/sfx/Before-Start {{ Glitch in the Grid.mp3", "stream")
    sounds.musicAfterStart = love.audio.newSource("source/sfx/After-Start }} Glitch in My Veins.mp3", "stream")
    sounds.powerUp = love.audio.newSource("source/sfx/PowerUp.wav", "static")
    sounds.enemyDeath = love.audio.newSource("source/sfx/bad person ded.wav", "static")
    sounds.enemyShoot = love.audio.newSource("source/sfx/bad pew pew pew.wav", "static")
    sounds.checkpoint = love.audio.newSource("source/sfx/checkpoint.wav", "static")
    sounds.playerDeath = love.audio.newSource("source/sfx/ded player- ded engine.wav", "static")
    sounds.playerHurt = love.audio.newSource("source/sfx/hurt.wav", "static")
    sounds.playerShoot = love.audio.newSource("source/sfx/pew-pew-pew.wav", "static")
    sounds.phaseComplete = love.audio.newSource("source/sfx/phasedone.wav", "static")
    
    -- Set loop property for music
    sounds.musicBeforeStart:setLooping(true)
    sounds.musicAfterStart:setLooping(true)
    
    -- Apply volume settings to all sounds
    game.applyVolumeSettings()
    
    -- Initialize power-ups
    powerUps.init(gridOffsetX, gridOffsetY)
    
    -- Start the initial music
    sounds.musicBeforeStart:play()
end

function game.update(dt)
    if gameState.isGameOver() then return end
    
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
    engine.update(dt, loadingBar.currentCheckpoint)
    
    -- Update bullets
    bullets.update(dt, enemies.list)
    
    -- Update enemies
    enemies.update(dt, loadingBar, gridOffsetX, gridOffsetY)
    
    -- Update game state
    gameState.update(dt)
    
    -- Update power-ups
    powerUps.update(dt, loadingBar.absoluteCheckpoint)
    
    -- Update UI elements based on player status
    ui.updatePlayerStatus(player.getHealth())
end

function game.draw()
    -- If showing power-up typing interface, only draw that
    if powerUps.showTypingInterface then
        powerUps.draw(fonts)
        return
    end

    -- Apply camera shake
    love.graphics.push()
    local shakeX, shakeY = camera.getOffset()
    love.graphics.translate(shakeX, shakeY)
    
    -- Draw loading bar
    loadingBar.draw(gridOffsetX, gridOffsetY, fonts)
    
    -- Draw grid
    ui.drawGrid(gridOffsetX, gridOffsetY, config.gridSize, config.cellSize, config.gridColor)
    
    -- Draw engine
    local showPrompt = not loadingBar.active and engine.isPlayerNearby(player.x, player.y)
    engine.draw(gridOffsetX, gridOffsetY, fonts, showPrompt)
    
    -- Draw enemies (this will also draw enemy bullets)
    enemies.draw(fonts, engine.instabilityLevel)
    
    -- Draw player
    player.draw(gridOffsetX, gridOffsetY, fonts)
    
    -- Draw player bullets
    bullets.draw()
    
    -- Draw score and game status
    ui.drawScore(gameState.getScore(), fonts.small)
    ui.drawPlayerStatus(fonts.small)
    
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
end

function game.keypressed(key)
    -- Handle power-up typing interface keypresses
    if powerUps.showTypingInterface then
        powerUps.keypressed(key)
        return
    end

    if gameState.isGameOver() and key == "r" then
        game.reset()
        return
    end

    if key == "e" and not loadingBar.active and not gameState.isGameOver() then
        if engine.isPlayerNearby(player.x, player.y) then
            loadingBar.activate()
        end
    end
    
    -- Add escape key to toggle pause
    if key == "escape" then
        gameState.togglePause()
    end
    
    -- Volume control shortcuts
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
    if powerUps.showTypingInterface then return end
    if not loadingBar.active or gameState.isPaused() or gameState.isGameOver() then return end
    
    if button == 1 then  -- Left click
        local px, py = player.getScreenPosition(gridOffsetX, gridOffsetY)
        bullets.create(px, py, x, y)
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
end

-- Get current volume settings
function game.getVolume()
    return volume
end

-- Expose sounds to other modules
function game.getSounds()
    return sounds
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