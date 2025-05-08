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

function engine.update(dt, checkpointLevel)
    engine.animTimer = engine.animTimer + dt
    engine.instabilityLevel = checkpointLevel / 5
    engine.animOffset = math.sin(engine.animTimer * (4 + engine.instabilityLevel * 4)) * 
                       (engine.unstableAmplitude + engine.instabilityLevel * 5)

    engine.pulseTimer = engine.pulseTimer + dt
    engine.pulseScale = 1 + (0.1 + engine.instabilityLevel * 0.1) * math.sin(engine.pulseTimer * (3 + engine.instabilityLevel * 3))
end

function engine.draw(gridOffsetX, gridOffsetY, fonts, showPrompt)
    local ex = gridOffsetX + (engine.x - 1) * config.cellSize + config.cellSize / 2
    local ey = gridOffsetY + (engine.y - 1) * config.cellSize + config.cellSize / 2 + engine.animOffset

    love.graphics.push()
    love.graphics.translate(ex, ey)
    love.graphics.scale(engine.pulseScale, engine.pulseScale)
    love.graphics.setColor(0.8, 0.2, 0.2)
    love.graphics.rectangle("fill", -20, -20, 40, 40)
    love.graphics.pop()

    love.graphics.setFont(fonts.large)
    love.graphics.setColor(1, 1, 1)
    local cheatText = "Cheat Engine"
    local cheatW = fonts.large:getWidth(cheatText)
    love.graphics.print(cheatText, ex - cheatW / 2, ey - 50)

    if showPrompt then
        local prompt = "> E To Start Payload <"
        love.graphics.setFont(fonts.small)
        local pw = fonts.small:getWidth(prompt)
        love.graphics.print(prompt, ex - pw / 2, ey + 30)
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
end

function engine.isPlayerNearby(playerX, playerY)
    return math.abs(playerX - engine.x) <= 1 and math.abs(playerY - engine.y) <= 1
end

return engine