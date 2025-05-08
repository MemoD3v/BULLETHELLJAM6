local player = {}
local config = require("modules.game.config")

-- Player state
player.x = math.ceil(config.gridSize / 2)
player.y = math.ceil(config.gridSize / 2) + 1
player.moveTimer = 0

function player.update(dt, gridSize)
    if player.moveTimer > 0 then
        player.moveTimer = player.moveTimer - dt
    else
        local moved = false
        if love.keyboard.isDown("w") and player.y > 1 then 
            player.y = player.y - 1 
            moved = true
        elseif love.keyboard.isDown("s") and player.y < gridSize then 
            player.y = player.y + 1 
            moved = true
        elseif love.keyboard.isDown("a") and player.x > 1 then 
            player.x = player.x - 1 
            moved = true
        elseif love.keyboard.isDown("d") and player.x < gridSize then 
            player.x = player.x + 1 
            moved = true
        end
        
        if moved then 
            player.moveTimer = config.moveCooldown 
        end
    end
end

function player.draw(gridOffsetX, gridOffsetY)
    love.graphics.setColor(config.playerColor)
    local px = gridOffsetX + (player.x - 1) * config.cellSize + (config.cellSize - config.playerSize) / 2
    local py = gridOffsetY + (player.y - 1) * config.cellSize + (config.cellSize - config.playerSize) / 2
    love.graphics.rectangle("fill", px, py, config.playerSize, config.playerSize)
end

function player.reset()
    player.x = math.ceil(config.gridSize / 2)
    player.y = math.ceil(config.gridSize / 2) + 1
    player.moveTimer = 0
end

function player.getScreenPosition(gridOffsetX, gridOffsetY)
    local px = gridOffsetX + (player.x - 1) * config.cellSize + config.cellSize / 2
    local py = gridOffsetY + (player.y - 1) * config.cellSize + config.cellSize / 2
    return px, py
end

return player