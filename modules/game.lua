local game = {}

local gridSize = 7
local cellSize = 60
local playerSize = 50
local playerX = math.ceil(gridSize / 2)
local playerY = math.ceil(gridSize / 2) + 1
local gridColor = {0.5, 0.5, 0.5}
local playerColor = {1, 1, 1}
local gridOffsetX, gridOffsetY = 0, 0
local moveCooldown = 0.15
local moveTimer = 0

local cameraShake = {
    intensity = 0,
    timer = 0,
    duration = 0,
    offsetX = 0,
    offsetY = 0
}

local loadingBar = {
    width = gridSize * cellSize * 0.95,
    height = 20,
    progress = 0,
    color = {0.2, 0.6, 1},
    bgColor = {0.1, 0.1, 0.1},
    text = "PAYLOAD",
    font = nil,
    active = false,
    currentCheckpoint = 0,
    checkpointTextAlpha = 0,
    checkpointTextTimer = 0,
    checkpointTextDuration = 2
}

local bullets = {}
local bulletSpeed = 400
local bulletWidth = 12
local bulletHeight = 4
local bulletColor = {1, 1, 1}
local bulletDamage = 25

local engine = {
    x = math.ceil(gridSize / 2),
    y = math.ceil(gridSize / 2),
    animOffset = 0,
    animTimer = 0,
    unstableAmplitude = 2,
    enemiesTouched = 0,
    maxEnemiesBeforeGameOver = 3,
    pulseTimer = 0,
    pulseScale = 1,
    instabilityLevel = 0
}

local enemyTypes = {
    {
        name = "Anti-Cheat",
        color = {0.8, 0.2, 0.2},
        health = 50,
        maxHealth = 50,
        speed = 0.5,
        unlockAt = 0,
        size = 30,
        damage = 10,
        score = 10
    },
    {
        name = "Players",
        color = {0.2, 0.5, 0.8},
        health = 80,
        maxHealth = 80,
        speed = 0.7,
        unlockAt = 1,
        size = 35,
        damage = 15,
        score = 20
    },
    {
        name = "Moderators",
        color = {0.8, 0.5, 0.2},
        health = 120,
        maxHealth = 120,
        speed = 0.6,
        unlockAt = 2,
        size = 40,
        damage = 20,
        score = 30
    },
    {
        name = "Admins",
        color = {0.5, 0.2, 0.8},
        health = 150,
        maxHealth = 150,
        speed = 0.8,
        unlockAt = 3,
        size = 45,
        damage = 25,
        score = 40
    },
    {
        name = "Developers",
        color = {0.2, 0.8, 0.5},
        health = 200,
        maxHealth = 200,
        speed = 1.0,
        unlockAt = 4,
        size = 50,
        damage = 30,
        score = 50
    }
}

local enemies = {}
local enemySpawnTimer = 0
local enemySpawnInterval = 3.0
local gameOver = false
local score = 0
local checkpointReached = false
local checkpointFlash = nil

local fontSmall = nil
local fontLarge = nil
local fontExtraLarge = nil
local fontMassive = nil

function game.load()
    local ww, wh = love.graphics.getDimensions()
    gridOffsetX = (ww - gridSize * cellSize) / 2
    gridOffsetY = (wh - gridSize * cellSize) / 2 + 40

    fontSmall = love.graphics.newFont("source/fonts/Jersey10.ttf", 16)
    fontLarge = love.graphics.newFont("source/fonts/Jersey10.ttf", 24)
    fontExtraLarge = love.graphics.newFont("source/fonts/Jersey10.ttf", 36)
    fontMassive = love.graphics.newFont("source/fonts/Jersey10.ttf", 48)
    loadingBar.font = fontLarge
end

function game.update(dt)
    if gameOver then return end

    if loadingBar.active then

        local baseShake = 0.5 + loadingBar.progress * 3

        local dangerShake = 0
        local engineX = gridOffsetX + (engine.x - 1) * cellSize + cellSize / 2
        local engineY = gridOffsetY + (engine.y - 1) * cellSize + cellSize / 2
        for _, e in ipairs(enemies) do
            local dist = math.sqrt((e.x - engineX)^2 + (e.y - engineY)^2)
            if dist < 200 then
                dangerShake = dangerShake + (200 - dist)/200 * 2
            end
        end

        cameraShake.intensity = baseShake + dangerShake
        cameraShake.duration = 0.5
        cameraShake.timer = cameraShake.duration
    end

    if cameraShake.timer > 0 then
        cameraShake.timer = cameraShake.timer - dt
        local progress = cameraShake.timer / cameraShake.duration
        local intensity = cameraShake.intensity * progress * (1 + engine.instabilityLevel * 0.5)
        cameraShake.offsetX = (love.math.random() * 2 - 1) * intensity
        cameraShake.offsetY = (love.math.random() * 2 - 1) * intensity
    else
        cameraShake.offsetX = 0
        cameraShake.offsetY = 0
    end

    if loadingBar.checkpointTextAlpha > 0 then
        loadingBar.checkpointTextTimer = loadingBar.checkpointTextTimer + dt
        loadingBar.checkpointTextAlpha = math.max(0, loadingBar.checkpointTextAlpha - dt/loadingBar.checkpointTextDuration)
    end

    if checkpointFlash then
        checkpointFlash = math.max(0, checkpointFlash - dt * 2)
        if checkpointFlash <= 0 then checkpointFlash = nil end
    end

    if moveTimer > 0 then
        moveTimer = moveTimer - dt
    else
        local moved = false
        if love.keyboard.isDown("w") and playerY > 1 then playerY = playerY - 1 moved = true
        elseif love.keyboard.isDown("s") and playerY < gridSize then playerY = playerY + 1 moved = true
        elseif love.keyboard.isDown("a") and playerX > 1 then playerX = playerX - 1 moved = true
        elseif love.keyboard.isDown("d") and playerX < gridSize then playerX = playerX + 1 moved = true
        end
        if moved then moveTimer = moveCooldown end
    end

    engine.animTimer = engine.animTimer + dt
    engine.instabilityLevel = loadingBar.currentCheckpoint / 5
    engine.animOffset = math.sin(engine.animTimer * (4 + engine.instabilityLevel * 4)) * 
                       (engine.unstableAmplitude + engine.instabilityLevel * 5)

    engine.pulseTimer = engine.pulseTimer + dt
    engine.pulseScale = 1 + (0.1 + engine.instabilityLevel * 0.1) * math.sin(engine.pulseTimer * (3 + engine.instabilityLevel * 3))

    if loadingBar.active then
        local oldProgress = loadingBar.progress
        loadingBar.progress = math.min(1, loadingBar.progress + dt * 0.01)

        local newCheckpoint = math.floor(loadingBar.progress * 5)
        if newCheckpoint > loadingBar.currentCheckpoint then
            loadingBar.currentCheckpoint = newCheckpoint
            loadingBar.checkpointTextAlpha = 1
            loadingBar.checkpointTextTimer = 0
            checkpointReached = true

            cameraShake.intensity = 2 + loadingBar.currentCheckpoint * 3
            cameraShake.duration = 1.5
            cameraShake.timer = cameraShake.duration
            checkpointFlash = 0.3
        end

        if not loadingBar.tickFlash then loadingBar.tickFlash = {} end
        local ticks = 5
        for i = 1, ticks - 1 do
            local threshold = i / ticks
            if oldProgress < threshold and loadingBar.progress >= threshold then
                loadingBar.tickFlash[i] = 0.3
            end
        end
    end

    if loadingBar.tickFlash then
        for i, time in pairs(loadingBar.tickFlash) do
            loadingBar.tickFlash[i] = time - dt
            if loadingBar.tickFlash[i] <= 0 then
                loadingBar.tickFlash[i] = nil
            end
        end
    end

    for i = #bullets, 1, -1 do
        local b = bullets[i]
        b.x = b.x + b.dx * bulletSpeed * dt
        b.y = b.y + b.dy * bulletSpeed * dt
        b.time = b.time + dt

        local bulletRemoved = false
        for j = #enemies, 1, -1 do
            local e = enemies[j]
            local dist = math.sqrt((b.x - e.x)^2 + (b.y - e.y)^2)
            if dist < e.size/2 + bulletWidth/2 then
                e.health = e.health - bulletDamage
                if e.health <= 0 then
                    score = score + e.type.score
                    table.remove(enemies, j)
                end
                table.remove(bullets, i)
                bulletRemoved = true
                break
            end
        end

        if not bulletRemoved and (b.x < 0 or b.x > love.graphics.getWidth() or
           b.y < 0 or b.y > love.graphics.getHeight()) then
            table.remove(bullets, i)
        end
    end

    if loadingBar.active then
        enemySpawnTimer = enemySpawnTimer + dt

        local currentSpawnInterval = math.max(0.5, 3 - loadingBar.progress * 2.5)

        if enemySpawnTimer >= currentSpawnInterval then
            enemySpawnTimer = 0

            local spawnCount = math.min(5, 1 + math.floor(loadingBar.progress * 5))

            for i = 1, spawnCount do

                local possibleTypes = {}
                for _, type in ipairs(enemyTypes) do
                    if type.unlockAt <= loadingBar.currentCheckpoint then
                        table.insert(possibleTypes, type)
                    end
                end

                if #possibleTypes > 0 then
                    local type = possibleTypes[love.math.random(#possibleTypes)]
                    local side = love.math.random(4)
                    local x, y

                    if side == 1 then 
                        x = love.math.random(gridOffsetX, gridOffsetX + gridSize * cellSize)
                        y = gridOffsetY - 50
                    elseif side == 2 then 
                        x = gridOffsetX + gridSize * cellSize + 50
                        y = love.math.random(gridOffsetY, gridOffsetY + gridSize * cellSize)
                    elseif side == 3 then 
                        x = love.math.random(gridOffsetX, gridOffsetX + gridSize * cellSize)
                        y = gridOffsetY + gridSize * cellSize + 50
                    else 
                        x = gridOffsetX - 50
                        y = love.math.random(gridOffsetY, gridOffsetY + gridSize * cellSize)
                    end

                    table.insert(enemies, {
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
    end

    for i = #enemies, 1, -1 do
        local e = enemies[i]
        e.animTimer = e.animTimer + dt

        local engineX = gridOffsetX + (engine.x - 1) * cellSize + cellSize / 2
        local engineY = gridOffsetY + (engine.y - 1) * cellSize + cellSize / 2 + engine.animOffset

        local dx = engineX - e.x
        local dy = engineY - e.y
        local dist = math.sqrt(dx^2 + dy^2)
        dx, dy = dx/dist, dy/dist

        e.x = e.x + dx * e.type.speed * 60 * dt
        e.y = e.y + dy * e.type.speed * 60 * dt

        if dist < 30 then
            table.remove(enemies, i)
            engine.enemiesTouched = engine.enemiesTouched + 1
            if engine.enemiesTouched >= engine.maxEnemiesBeforeGameOver then
                gameOver = true
            end
        end
    end
end

function game.draw()

    if checkpointFlash then
        love.graphics.setColor(1, 0, 0, checkpointFlash)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    end

    love.graphics.push()
    love.graphics.translate(cameraShake.offsetX, cameraShake.offsetY)

    local barX = gridOffsetX + (gridSize * cellSize - loadingBar.width) / 2
    local barY = gridOffsetY - 40

    love.graphics.setColor(loadingBar.bgColor)
    love.graphics.rectangle("fill", barX, barY, loadingBar.width, loadingBar.height)

    local r, g, b = unpack(loadingBar.color)
    local animFactor = 0.5 + 0.5 * math.sin(love.timer.getTime() * 4)
    love.graphics.setColor(r * animFactor, g * animFactor, b)
    love.graphics.rectangle("fill", barX, barY, loadingBar.width * loadingBar.progress, loadingBar.height)

    local numTicks = 5
    for i = 1, numTicks - 1 do
        local progressPerTick = i / numTicks
        local tickX = barX + loadingBar.width * progressPerTick

        local flash = loadingBar.tickFlash and loadingBar.tickFlash[i]
        if flash then
            local alpha = math.min(1, flash * 5)
            love.graphics.setColor(1, 1, 0.3, alpha)
        elseif loadingBar.progress >= progressPerTick then
            love.graphics.setColor(1, 1, 1, 1)
        else
            love.graphics.setColor(1, 1, 1, 0.2)
        end
        love.graphics.setLineWidth(2)
        love.graphics.line(tickX, barY, tickX, barY + loadingBar.height)
    end

    love.graphics.setFont(loadingBar.font)
    love.graphics.setColor(1, 1, 1)
    local textWidth = loadingBar.font:getWidth(loadingBar.text)
    love.graphics.print(loadingBar.text, barX + (loadingBar.width - textWidth) / 2, barY - 30)

    love.graphics.setColor(gridColor)
    love.graphics.setLineWidth(2)
    for x = 0, gridSize do
        love.graphics.line(gridOffsetX + x * cellSize, gridOffsetY, gridOffsetX + x * cellSize, gridOffsetY + gridSize * cellSize)
    end
    for y = 0, gridSize do
        love.graphics.line(gridOffsetX, gridOffsetY + y * cellSize, gridOffsetX + gridSize * cellSize, gridOffsetY + y * cellSize)
    end

    local ex = gridOffsetX + (engine.x - 1) * cellSize + cellSize / 2
    local ey = gridOffsetY + (engine.y - 1) * cellSize + cellSize / 2 + engine.animOffset

    love.graphics.push()
    love.graphics.translate(ex, ey)
    love.graphics.scale(engine.pulseScale, engine.pulseScale)
    love.graphics.setColor(0.8, 0.2, 0.2)
    love.graphics.rectangle("fill", -20, -20, 40, 40)
    love.graphics.pop()

    love.graphics.setFont(fontLarge)
    love.graphics.setColor(1, 1, 1)
    local cheatText = "Cheat Engine"
    local cheatW = fontLarge:getWidth(cheatText)
    love.graphics.print(cheatText, ex - cheatW / 2, ey - 50)

    local currentTime = love.timer.getTime()
    for _, e in ipairs(enemies) do

        if currentTime - e.spawnTime < 0.5 then
            local spawnProgress = (currentTime - e.spawnTime) / 0.5
            love.graphics.setColor(e.type.color[1], e.type.color[2], e.type.color[3], spawnProgress)
            local scale = 0.5 + spawnProgress * 0.5
            love.graphics.circle("fill", e.x, e.y, e.size/2 * scale)
        end

        local wobbleX = math.sin(e.animTimer * 3) * engine.instabilityLevel * 5
        local wobbleY = math.cos(e.animTimer * 3.5) * engine.instabilityLevel * 5

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

        love.graphics.setFont(fontSmall)
        love.graphics.setColor(1, 1, 1)
        local nameWidth = fontSmall:getWidth(e.type.name)
        love.graphics.print(e.type.name, -nameWidth/2, -e.size/2 - 25)

        love.graphics.pop()
    end

    love.graphics.setColor(playerColor)
    local px = gridOffsetX + (playerX - 1) * cellSize + (cellSize - playerSize) / 2
    local py = gridOffsetY + (playerY - 1) * cellSize + (cellSize - playerSize) / 2
    love.graphics.rectangle("fill", px, py, playerSize, playerSize)

    if not loadingBar.active and math.abs(playerX - engine.x) <= 1 and math.abs(playerY - engine.y) <= 1 then
        local prompt = "> E To Start Payload <"
        love.graphics.setFont(fontSmall)
        local pw = fontSmall:getWidth(prompt)
        love.graphics.print(prompt, ex - pw / 2, ey + 30)
    end

    love.graphics.setColor(bulletColor)
    for _, b in ipairs(bullets) do
        love.graphics.push()
        love.graphics.translate(b.x, b.y)
        local animAngle = b.angle + math.sin(b.time * 10) * 0.1
        love.graphics.rotate(animAngle)
        love.graphics.rectangle("fill", -bulletWidth / 2, -bulletHeight / 2, bulletWidth, bulletHeight)
        love.graphics.pop()
    end

    love.graphics.setFont(fontSmall)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("SCORE: " .. score, 20, 20)

    if loadingBar.checkpointTextAlpha > 0 then
        local text = "UNSTABLE GAME DETECTED, CRASH EXPECTED"
        love.graphics.setFont(fontMassive)

        local flash = math.sin(loadingBar.checkpointTextTimer * 15) > 0
        local alpha = loadingBar.checkpointTextAlpha * (flash and 1 or 0.3)

        love.graphics.setColor(1, 0, 0, alpha)
        local textWidth = fontMassive:getWidth(text)
        love.graphics.print(text, 
                          love.graphics.getWidth()/2 - textWidth/2, 
                          love.graphics.getHeight()/2 - 150)
    end

    if gameOver then
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

        love.graphics.setFont(fontMassive)
        love.graphics.setColor(1, 0, 0)
        local gameOverText = "GAME OVER"
        local gameOverWidth = fontMassive:getWidth(gameOverText)
        love.graphics.print(gameOverText, 
                          love.graphics.getWidth()/2 - gameOverWidth/2, 
                          love.graphics.getHeight()/2 - 100)

        love.graphics.setFont(fontExtraLarge)
        love.graphics.setColor(1, 1, 1)
        local scoreText = "FINAL SCORE: " .. score
        local scoreWidth = fontExtraLarge:getWidth(scoreText)
        love.graphics.print(scoreText, 
                          love.graphics.getWidth()/2 - scoreWidth/2, 
                          love.graphics.getHeight()/2 + 20)

        love.graphics.setFont(fontLarge)
        local restartText = "Press R to restart"
        local restartWidth = fontLarge:getWidth(restartText)
        love.graphics.print(restartText, 
                          love.graphics.getWidth()/2 - restartWidth/2, 
                          love.graphics.getHeight()/2 + 80)
    end

    love.graphics.pop()
end

function game.keypressed(key)
    if gameOver and key == "r" then

        game.reset()
        return
    end

    if key == "e" and not loadingBar.active and not gameOver then
        if math.abs(playerX - engine.x) <= 1 and math.abs(playerY - engine.y) <= 1 then
            loadingBar.active = true
        end
    end
end

function game.mousepressed(x, y, button)
    if button == 1 and not gameOver then
        local px = gridOffsetX + (playerX - 1) * cellSize + cellSize / 2
        local py = gridOffsetY + (playerY - 1) * cellSize + cellSize / 2

        local dx = x - px
        local dy = y - py
        local len = math.sqrt(dx * dx + dy * dy)
        dx, dy = dx / len, dy / len

        table.insert(bullets, {
            x = px,
            y = py,
            dx = dx,
            dy = dy,
            angle = math.atan2(dy, dx),
            time = 0
        })
    end
end

function game.reset()

    playerX = math.ceil(gridSize / 2)
    playerY = math.ceil(gridSize / 2) + 1

    loadingBar.progress = 0
    loadingBar.active = false
    loadingBar.currentCheckpoint = 0
    loadingBar.tickFlash = nil
    loadingBar.checkpointTextAlpha = 0

    engine.enemiesTouched = 0
    engine.pulseTimer = 0
    engine.instabilityLevel = 0

    cameraShake.intensity = 0
    cameraShake.timer = 0

    bullets = {}
    enemies = {}
    enemySpawnTimer = 0

    score = 0

    gameOver = false
    checkpointReached = false
    checkpointFlash = nil
end

function game.resize(w, h)
    local gridWidth = gridSize * cellSize
    local gridHeight = gridSize * cellSize
    gridOffsetX = (w - gridWidth) / 2
    gridOffsetY = (h - gridHeight) / 2 + 40
end

return game