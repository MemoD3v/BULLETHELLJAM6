local enemies = {}
local config = require("modules.game.config")
local engine = require("modules.game.engine")
local gameState = require("modules.game.gameState")

enemies.list = {}
enemies.spawnTimer = 0

function enemies.update(dt, loadingBar, gridOffsetX, gridOffsetY)
    if loadingBar.active then
        enemies.spawnTimer = enemies.spawnTimer + dt

        local currentSpawnInterval = math.max(0.5, 3 - loadingBar.progress * 2.5)

        if enemies.spawnTimer >= currentSpawnInterval then
            enemies.spawnTimer = 0
            enemies.spawn(loadingBar.currentCheckpoint, gridOffsetX, gridOffsetY)
        end
    end

    for i = #enemies.list, 1, -1 do
        local e = enemies.list[i]
        e.animTimer = e.animTimer + dt

        local engineX = gridOffsetX + (engine.x - 1) * config.cellSize + config.cellSize / 2
        local engineY = gridOffsetY + (engine.y - 1) * config.cellSize + config.cellSize / 2 + engine.animOffset

        local dx = engineX - e.x
        local dy = engineY - e.y
        local dist = math.sqrt(dx^2 + dy^2)
        dx, dy = dx/dist, dy/dist

        e.x = e.x + dx * e.type.speed * 60 * dt
        e.y = e.y + dy * e.type.speed * 60 * dt

        if dist < 30 then
            table.remove(enemies.list, i)
            engine.incrementEnemies()
            if engine.enemiesTouched >= config.engineMaxEnemiesBeforeGameOver then
                gameState.setGameOver(true)
            end
        end
    end
end

function enemies.spawn(checkpoint, gridOffsetX, gridOffsetY)
    local spawnCount = math.min(5, 1 + math.floor(checkpoint * 5 / 5))

    for i = 1, spawnCount do
        local possibleTypes = {}
        for _, type in ipairs(config.enemyTypes) do
            if type.unlockAt <= checkpoint then
                table.insert(possibleTypes, type)
            end
        end

        if #possibleTypes > 0 then
            local type = possibleTypes[love.math.random(#possibleTypes)]
            local side = love.math.random(4)
            local x, y

            if side == 1 then 
                x = love.math.random(gridOffsetX, gridOffsetX + config.gridSize * config.cellSize)
                y = gridOffsetY - 50
            elseif side == 2 then 
                x = gridOffsetX + config.gridSize * config.cellSize + 50
                y = love.math.random(gridOffsetY, gridOffsetY + config.gridSize * config.cellSize)
            elseif side == 3 then 
                x = love.math.random(gridOffsetX, gridOffsetX + config.gridSize * config.cellSize)
                y = gridOffsetY + config.gridSize * config.cellSize + 50
            else 
                x = gridOffsetX - 50
                y = love.math.random(gridOffsetY, gridOffsetY + config.gridSize * config.cellSize)
            end

            table.insert(enemies.list, {
                x = x,
                y = y,
                type = type,
                health = type.health,
                maxHealth = type.health,
                size = type.size,
                animTimer = 0,
                spawnTime = love.timer.getTime()
            })
        end
    end
end

function enemies.draw(fonts, instabilityLevel)
    local currentTime = love.timer.getTime()
    for _, e in ipairs(enemies.list) do
        if currentTime - e.spawnTime < 0.5 then
            local spawnProgress = (currentTime - e.spawnTime) / 0.5
            love.graphics.setColor(e.type.color[1], e.type.color[2], e.type.color[3], spawnProgress)
            local scale = 0.5 + spawnProgress * 0.5
            love.graphics.circle("fill", e.x, e.y, e.size/2 * scale)
        end

        local wobbleX = math.sin(e.animTimer * 3) * instabilityLevel * 5
        local wobbleY = math.cos(e.animTimer * 3.5) * instabilityLevel * 5

        love.graphics.push()
        love.graphics.translate(e.x + wobbleX, e.y + wobbleY)

        love.graphics.setColor(e.type.color)
        love.graphics.circle("fill", 0, 0, e.size/2)

        local healthRatio = e.health / e.maxHealth
        local healthBarWidth = e.size
        local healthBarHeight = 5

        love.graphics.setColor(0.1, 0.1, 0.1)
        love.graphics.rectangle("fill", -healthBarWidth/2, -e.size/2 - 10, 
                              healthBarWidth, healthBarHeight)

        love.graphics.setColor(0.2, 1, 0.2)
        love.graphics.rectangle("fill", -healthBarWidth/2, -e.size/2 - 10, 
                              healthBarWidth * healthRatio, healthBarHeight)

        love.graphics.setFont(fonts.small)
        love.graphics.setColor(1, 1, 1)
        local nameWidth = fonts.small:getWidth(e.type.name)
        love.graphics.print(e.type.name, -nameWidth/2, -e.size/2 - 25)

        love.graphics.pop()
    end
end

function enemies.reset()
    enemies.list = {}
    enemies.spawnTimer = 0
end

return enemies