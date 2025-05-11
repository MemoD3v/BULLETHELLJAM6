local enemies = {}
local config = require("modules.game.config")
local engine = require("modules.game.engine")
local gameState = require("modules.game.gameState")
local enemyBullets = require("modules.game.enemyBullets")

local enemySprites = love.graphics.newImage("source/sprites/enemies.png")
local spriteSize = 16

enemies.list = {}
enemies.spawnTimer = 0

function enemies.update(dt, loadingBar, gridOffsetX, gridOffsetY)
    if loadingBar.active then
        enemies.spawnTimer = enemies.spawnTimer + dt

        local absoluteCheckpoint = (loadingBar.currentPhase - 1) * loadingBar.checkpointsPerPhase + loadingBar.currentCheckpoint
        local currentSpawnInterval = math.max(0.5, 3 - (absoluteCheckpoint * 0.25))

        if enemies.spawnTimer >= currentSpawnInterval then
            enemies.spawnTimer = 0
            enemies.spawn(absoluteCheckpoint, gridOffsetX, gridOffsetY)
        end
    end

    for i = #enemies.list, 1, -1 do
        local e = enemies.list[i]
        e.animTimer = e.animTimer + dt
        
        if e.fireCooldown > 0 then
            e.fireCooldown = e.fireCooldown - dt
        end

        local engineX = gridOffsetX + (engine.x - 1) * config.cellSize + config.cellSize / 2
        local engineY = gridOffsetY + (engine.y - 1) * config.cellSize + config.cellSize / 2 + engine.animOffset

        local dx = engineX - e.x
        local dy = engineY - e.y
        local dist = math.sqrt(dx^2 + dy^2)
        dx, dy = dx/dist, dy/dist

        e.x = e.x + dx * e.type.speed * 60 * dt
        e.y = e.y + dy * e.type.speed * 60 * dt
        
        if loadingBar.active and e.fireCooldown <= 0 and dist > 100 then
            e.fireCooldown = e.type.fireRate
            
            if e.type.bulletPattern == "single" then
                enemyBullets.create(e.x, e.y, e.type, gridOffsetX, gridOffsetY)
            elseif e.type.bulletPattern == "double" then
                local offset = 0.2
                local ex, ey = e.x, e.y
                for j = -1, 1, 2 do
                    local bulletType = {}
                    for k, v in pairs(e.type) do bulletType[k] = v end
                    bulletType.patternAngleOffset = offset * j
                    enemyBullets.create(ex, ey, bulletType, gridOffsetX, gridOffsetY)
                end
            elseif e.type.bulletPattern == "triple" then
                local offset = 0.25
                local ex, ey = e.x, e.y
                for j = -1, 1 do
                    local bulletType = {}
                    for k, v in pairs(e.type) do bulletType[k] = v end
                    bulletType.patternAngleOffset = offset * j
                    enemyBullets.create(ex, ey, bulletType, gridOffsetX, gridOffsetY)
                end
            elseif e.type.bulletPattern == "spread" then
                local offset = 0.15
                local ex, ey = e.x, e.y
                for j = -2, 2 do
                    local bulletType = {}
                    for k, v in pairs(e.type) do bulletType[k] = v end
                    bulletType.patternAngleOffset = offset * j
                    enemyBullets.create(ex, ey, bulletType, gridOffsetX, gridOffsetY)
                end
            elseif e.type.bulletPattern == "wave" or e.type.bulletPattern == "burst" then
                local count = e.type.bulletPattern == "wave" and 3 or 6
                local ex, ey = e.x, e.y
                
                for j = 1, count do
                    local bulletType = {}
                    for k, v in pairs(e.type) do bulletType[k] = v end
                    bulletType.bulletSpeed = e.type.bulletSpeed * (1 - 0.1 * j)
                    enemyBullets.create(ex, ey, bulletType, gridOffsetX, gridOffsetY)
                    
                    local sounds = require("modules.init").getSounds()
                    if sounds and sounds.enemyShoot then
                        sounds.enemyShoot:clone():play()
                    end
                end
            end
        end

        if dist < 30 then
            table.remove(enemies.list, i)
            engine.incrementEnemies()
            if engine.enemiesTouched >= config.engineMaxEnemiesBeforeGameOver then
                local sounds = require("modules.init").getSounds()
                if sounds and sounds.playerDeath then
                    sounds.playerDeath:stop()
                    sounds.playerDeath:play()
                end
                
                gameState.setGameOver(true)
            end
            
            local sounds = require("modules.init").getSounds()
            if sounds and sounds.enemyDeath then
                sounds.enemyDeath:clone():play()
            end
        end
    end
    
    enemyBullets.update(dt, gridOffsetX, gridOffsetY)
end

function enemies.spawn(absoluteCheckpoint, gridOffsetX, gridOffsetY)
    local baseSpawnCount = 1 + math.floor(absoluteCheckpoint * 0.5)
    local spawnCount = math.min(7, baseSpawnCount)

    for i = 1, spawnCount do
        local possibleTypes = {}
        for _, type in ipairs(config.enemyTypes) do
            if type.unlockAt <= absoluteCheckpoint then
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
                spawnTime = love.timer.getTime(),
                fireCooldown = type.fireRate * (0.5 + love.math.random() * 0.5)
            })
        end
    end
end

function enemies.draw(fonts, instabilityLevel)
    local currentTime = love.timer.getTime()
    enemyBullets.draw()
    
    for _, e in ipairs(enemies.list) do
        local spriteIndex = e.type.spriteIndex or 0
        local quad = love.graphics.newQuad(spriteIndex * spriteSize, 0, spriteSize, spriteSize, enemySprites:getDimensions())
        
        if currentTime - e.spawnTime < 0.5 then
            local spawnProgress = (currentTime - e.spawnTime) / 0.5
            love.graphics.setColor(e.type.color[1], e.type.color[2], e.type.color[3], spawnProgress)
            local scale = (0.5 + spawnProgress * 0.5) * (e.size / spriteSize)
            love.graphics.draw(enemySprites, quad, e.x, e.y, 0, scale, scale, spriteSize/2, spriteSize/2)
        end

        local wobbleX = math.sin(e.animTimer * 3) * instabilityLevel * 5
        local wobbleY = math.cos(e.animTimer * 3.5) * instabilityLevel * 5

        love.graphics.push()
        love.graphics.translate(e.x + wobbleX, e.y + wobbleY)

        love.graphics.setColor(e.type.color)
        love.graphics.draw(enemySprites, quad, 0, 0, 0, e.size/spriteSize, e.size/spriteSize, spriteSize/2, spriteSize/2)
        
        if e.fireCooldown <= 0.3 then
            local glowIntensity = math.abs(math.sin(e.animTimer * 10)) * 0.5
            love.graphics.setColor(e.type.color[1], e.type.color[2], e.type.color[3], glowIntensity)
            love.graphics.draw(enemySprites, quad, 0, 0, 0, (e.size/spriteSize) * 1.2, (e.size/spriteSize) * 1.2, spriteSize/2, spriteSize/2)
        end

        local healthRatio = e.health / e.maxHealth
        local healthBarWidth = e.size
        local healthBarHeight = 5

        love.graphics.setColor(0.1, 0.1, 0.1)
        love.graphics.rectangle("fill", -healthBarWidth/2, -e.size/2 - 10, healthBarWidth, healthBarHeight)

        love.graphics.setColor(0.2, 1, 0.2)
        love.graphics.rectangle("fill", -healthBarWidth/2, -e.size/2 - 10, healthBarWidth * healthRatio, healthBarHeight)

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
    enemyBullets.reset()
end

return enemies