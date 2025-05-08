local ui = {}

function ui.drawGrid(gridOffsetX, gridOffsetY, gridSize, cellSize, gridColor)
    love.graphics.setColor(gridColor)
    love.graphics.setLineWidth(2)
    for x = 0, gridSize do
        love.graphics.line(gridOffsetX + x * cellSize, gridOffsetY, 
                          gridOffsetX + x * cellSize, gridOffsetY + gridSize * cellSize)
    end
    for y = 0, gridSize do
        love.graphics.line(gridOffsetX, gridOffsetY + y * cellSize, 
                          gridOffsetX + gridSize * cellSize, gridOffsetY + y * cellSize)
    end
end

function ui.drawScore(score, font)
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("SCORE: " .. score, 20, 20)
end

function ui.drawGameOver(score, fonts)
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    love.graphics.setFont(fonts.massive)
    love.graphics.setColor(1, 0, 0)
    local gameOverText = "GAME OVER"
    local gameOverWidth = fonts.massive:getWidth(gameOverText)
    love.graphics.print(gameOverText, 
                      love.graphics.getWidth()/2 - gameOverWidth/2, 
                      love.graphics.getHeight()/2 - 100)

    love.graphics.setFont(fonts.extraLarge)
    love.graphics.setColor(1, 1, 1)
    local scoreText = "FINAL SCORE: " .. score
    local scoreWidth = fonts.extraLarge:getWidth(scoreText)
    love.graphics.print(scoreText, 
                      love.graphics.getWidth()/2 - scoreWidth/2, 
                      love.graphics.getHeight()/2 + 20)

    love.graphics.setFont(fonts.large)
    local restartText = "Press R to restart"
    local restartWidth = fonts.large:getWidth(restartText)
    love.graphics.print(restartText, 
                      love.graphics.getWidth()/2 - restartWidth/2, 
                      love.graphics.getHeight()/2 + 80)
end

return ui