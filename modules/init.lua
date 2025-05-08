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

-- Grid positioning
local gridOffsetX, gridOffsetY = 0, 0

-- Fonts
local fonts = {
    small = nil,
    large = nil,
    extraLarge = nil,
    massive = nil
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
end

function game.update(dt)
    if gameState.isGameOver() then return end
    
    -- Don't update game mechanics when paused, but still update visual effects
    if gameState.isPaused() then
        gameState.update(dt)
        return
    end

    -- Update loading bar and checkpoints
    loadingBar.update(dt)
    
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
    player.update(dt, config.gridSize)
    
    -- Update engine animation and state
    engine.update(dt, loadingBar.currentCheckpoint)
    
    -- Update bullets
    bullets.update(dt, enemies.list)
    
    -- Update enemies
    enemies.update(dt, loadingBar, gridOffsetX, gridOffsetY)
    
    -- Update game state
    gameState.update(dt)
    
    -- Update UI elements based on player status
    ui.updatePlayerStatus(player.getHealth())
end

function game.draw()
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
    player.draw(gridOffsetX, gridOffsetY)
    
    -- Draw player bullets
    bullets.draw()
    
    -- Draw score and game status
    ui.drawScore(gameState.getScore(), fonts.small)
    ui.drawPlayerStatus(fonts.small)
    
    -- Draw game over screen if needed
    if gameState.isGameOver() then
        ui.drawGameOver(gameState.getScore(), fonts)
    end
    
    -- Draw pause overlay if paused
    if gameState.isPaused() then
        gameState.drawPauseOverlay(fonts)
    end
    
    love.graphics.pop()
end

function game.keypressed(key)
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
end

function game.mousepressed(x, y, button)
    if button == 1 and not gameState.isGameOver() then
        local px, py = player.getScreenPosition(gridOffsetX, gridOffsetY)
        bullets.create(px, py, x, y)
    end
end

function game.reset()
    player.reset()
    loadingBar.reset()
    engine.reset()
    camera.reset()
    bullets.reset()
    enemies.reset()
    gameState.reset()
end

function game.resize(w, h)
    gridOffsetX = (w - config.gridSize * config.cellSize) / 2
    gridOffsetY = (h - config.gridSize * config.cellSize) / 2 + 40
end

return game