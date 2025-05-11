local engine = {}
local config = require("modules.game.config")

engine.x = math.ceil(config.gridSize / 2)
engine.y = math.ceil(config.gridSize / 2)
engine.animOffset = 0
engine.animTimer = 0
engine.unstableAmplitude = config.engineUnstableAmplitude
engine.enemiesTouched = 0
engine.pulseTimer = 0
engine.pulseScale = 1
engine.instabilityLevel = 0
engine.shielded = false
engine.shieldTimer = 0
engine.shieldPulse = 0

function engine.update(dt, checkpointLevel)
    engine.animTimer = engine.animTimer + dt
    engine.instabilityLevel = checkpointLevel / 5
    engine.animOffset = math.sin(engine.animTimer * (4 + engine.instabilityLevel * 4)) * 
                       (engine.unstableAmplitude + engine.instabilityLevel * 5)

    engine.pulseTimer = engine.pulseTimer + dt
    engine.pulseScale = 1 + (0.1 + engine.instabilityLevel * 0.1) * math.sin(engine.pulseTimer * (3 + engine.instabilityLevel * 3))
    
    -- Update shield effect
    if engine.shielded then
        engine.shieldTimer = engine.shieldTimer + dt
        engine.shieldPulse = 0.5 + 0.5 * math.sin(engine.shieldTimer * 5)
    end
end

function engine.draw(gridOffsetX, gridOffsetY, fonts, showPrompt)
    local ex = gridOffsetX + (engine.x - 1) * config.cellSize + config.cellSize / 2
    local ey = gridOffsetY + (engine.y - 1) * config.cellSize + config.cellSize / 2 + engine.animOffset

    -- Draw shield if active
    if engine.shielded then
        local shieldSize = 60 + engine.shieldPulse * 10
        love.graphics.setColor(0.3, 0.7, 1, 0.3 + engine.shieldPulse * 0.2)
        love.graphics.circle("fill", ex, ey, shieldSize)
        love.graphics.setColor(0.4, 0.8, 1, 0.6 + engine.shieldPulse * 0.4)
        love.graphics.circle("line", ex, ey, shieldSize)
    end

    -- Draw the main cheat engine body
    love.graphics.push()
    love.graphics.translate(ex, ey)
    love.graphics.scale(engine.pulseScale, engine.pulseScale)
    
    -- Draw the engine base
    love.graphics.setColor(0.8, 0.2, 0.2)
    love.graphics.rectangle("fill", -25, -25, 50, 50)
    
    -- Draw the mini-monitor frame
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.rectangle("fill", -40, -80, 80, 50)  -- Monitor base
    
    -- Get the game canvas from init module
    local gameCanvas = require("modules.init").getGameCanvas()
    
    -- Draw the mini game screen if available
    if gameCanvas then
        -- Draw a monitor background first (dark gray)
        love.graphics.setColor(0.1, 0.1, 0.1, 1)
        love.graphics.rectangle("fill", -35, -75, 70, 45) -- Screen background
        
        -- Draw screen with full opacity
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(gameCanvas, -35, -75, 0, 0.1, 0.1)  -- Slightly larger scale, full opacity
        
        -- Draw screen edge highlights
        love.graphics.setColor(0.3, 0.3, 0.3, 1)
        love.graphics.rectangle("line", -35, -75, 70, 45) -- Screen border
        
        -- Draw scanlines for CRT effect
        love.graphics.setColor(0, 0, 0, 0.3)
        for i = 0, 18 do
            love.graphics.line(-35, -75 + i * 2.5, 35, -75 + i * 2.5)
        end
        
        -- Draw screen glint
        love.graphics.setColor(1, 1, 1, 0.2 + 0.1 * math.sin(love.timer.getTime() * 2))
        love.graphics.polygon("fill", -35, -75, -15, -75, -30, -60, -35, -65)
    end
    
    -- Draw flashing lights/buttons
    love.graphics.setColor(0, 1, 0, 0.5 + 0.5 * math.sin(love.timer.getTime() * 5))
    love.graphics.circle("fill", -15, 15, 4)
    love.graphics.setColor(1, 0, 0, 0.5 + 0.5 * math.sin(love.timer.getTime() * 3))
    love.graphics.circle("fill", 0, 15, 4)
    love.graphics.setColor(0, 0.5, 1, 0.5 + 0.5 * math.sin(love.timer.getTime() * 7))
    love.graphics.circle("fill", 15, 15, 4)
    
    love.graphics.pop()

    -- Draw the cheat engine text
    love.graphics.setFont(fonts.large)
    love.graphics.setColor(1, 1, 1)
    local cheatText = "Cheat Engine"
    local cheatW = fonts.large:getWidth(cheatText)
    love.graphics.print(cheatText, ex - cheatW / 2, ey - 110)

    if showPrompt then
        local prompt = "> E To Start Payload <"
        love.graphics.setFont(fonts.small)
        local pw = fonts.small:getWidth(prompt)
        love.graphics.print(prompt, ex - pw / 2, ey + 40)
    end
    
    return ex, ey
end

function engine.incrementEnemies()
    engine.enemiesTouched = engine.enemiesTouched + 1
end

function engine.reset()
    engine.animOffset = 0
    engine.animTimer = 0
    engine.enemiesTouched = 0
    engine.pulseTimer = 0
    engine.pulseScale = 1
    engine.instabilityLevel = 0
    engine.shielded = false
    engine.shieldTimer = 0
    engine.shieldPulse = 0
end

function engine.isPlayerNearby(playerX, playerY)
    return math.abs(playerX - engine.x) <= 1 and math.abs(playerY - engine.y) <= 1
end

return engine