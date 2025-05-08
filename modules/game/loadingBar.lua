local loadingBar = {}
local config = require("modules.game.config")
local camera = require("modules.game.camera")

loadingBar.width = config.gridSize * config.cellSize * 0.95
loadingBar.height = config.loadingBarHeight
loadingBar.progress = 0
loadingBar.color = config.loadingBarColor
loadingBar.bgColor = config.loadingBarBgColor
loadingBar.text = config.loadingBarText
loadingBar.font = nil
loadingBar.active = false
loadingBar.currentCheckpoint = 0
loadingBar.checkpointTextAlpha = 0
loadingBar.checkpointTextTimer = 0
loadingBar.checkpointTextDuration = 2
loadingBar.tickFlash = nil

loadingBar.checkpointFlash = nil

function loadingBar.update(dt)
    if loadingBar.checkpointTextAlpha > 0 then
        loadingBar.checkpointTextTimer = loadingBar.checkpointTextTimer + dt
        loadingBar.checkpointTextAlpha = math.max(0, loadingBar.checkpointTextAlpha - dt/loadingBar.checkpointTextDuration)
    end

    if loadingBar.checkpointFlash then
        loadingBar.checkpointFlash = math.max(0, loadingBar.checkpointFlash - dt * 2)
        if loadingBar.checkpointFlash <= 0 then loadingBar.checkpointFlash = nil end
    end

    if loadingBar.active then
        local oldProgress = loadingBar.progress
        loadingBar.progress = math.min(1, loadingBar.progress + dt * 0.01)

        local newCheckpoint = math.floor(loadingBar.progress * 5)
        if newCheckpoint > loadingBar.currentCheckpoint then
            loadingBar.currentCheckpoint = newCheckpoint
            loadingBar.checkpointTextAlpha = 1
            loadingBar.checkpointTextTimer = 0
            loadingBar.checkpointReached = true

            camera.shake(2 + loadingBar.currentCheckpoint * 3, 1.5)
            loadingBar.checkpointFlash = 0.3
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
end

function loadingBar.draw(gridOffsetX, gridOffsetY, fonts)
    if loadingBar.checkpointFlash then
        love.graphics.setColor(1, 0, 0, loadingBar.checkpointFlash)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    end

    local barX = gridOffsetX + (config.gridSize * config.cellSize - loadingBar.width) / 2
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

    if loadingBar.checkpointTextAlpha > 0 then
        local text = "UNSTABLE GAME DETECTED, CRASH EXPECTED"
        love.graphics.setFont(fonts.massive)

        local flash = math.sin(loadingBar.checkpointTextTimer * 15) > 0
        local alpha = loadingBar.checkpointTextAlpha * (flash and 1 or 0.3)

        love.graphics.setColor(1, 0, 0, alpha)
        local textWidth = fonts.massive:getWidth(text)
        love.graphics.print(text, 
                          love.graphics.getWidth()/2 - textWidth/2, 
                          love.graphics.getHeight()/2 - 150)
    end
end

function loadingBar.activate()
    loadingBar.active = true
end

function loadingBar.reset()
    loadingBar.progress = 0
    loadingBar.active = false
    loadingBar.currentCheckpoint = 0
    loadingBar.tickFlash = nil
    loadingBar.checkpointTextAlpha = 0
    loadingBar.checkpointReached = false
    loadingBar.checkpointFlash = nil
end

return loadingBar