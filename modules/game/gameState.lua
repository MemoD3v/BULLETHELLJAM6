local gameState = {}

gameState.gameOver = false
gameState.paused = false
gameState.pauseTextAlpha = 0
gameState.pauseTextTimer = 0
gameState.score = 0
gameState.checkpointReached = false
gameState.victory = false  -- Whether the player has won (versus just died)

function gameState.update(dt)
    -- Handle pause text animation
    if gameState.pauseTextAlpha > 0 then
        gameState.pauseTextTimer = gameState.pauseTextTimer + dt
        gameState.pauseTextAlpha = math.max(0, gameState.pauseTextAlpha - dt)
    end
end

function gameState.increaseScore(amount)
    gameState.score = gameState.score + amount
end

function gameState.setGameOver(state)
    gameState.gameOver = state
end

function gameState.isGameOver()
    return gameState.gameOver
end

function gameState.getScore()
    return gameState.score
end

function gameState.setVictory(state)
    gameState.victory = state
    if state == true then
        gameState.gameOver = true  -- Victory also means game over (but in a good way)
    end
end

function gameState.isVictory()
    return gameState.victory
end

function gameState.reset()
    gameState.gameOver = false
    gameState.paused = false
    gameState.pauseTextAlpha = 0
    gameState.pauseTextTimer = 0
    gameState.score = 0
    gameState.checkpointReached = false
    gameState.victory = false
end

function gameState.togglePause()
    -- Don't allow pausing if game is over
    if gameState.gameOver then
        return
    end
    
    gameState.paused = not gameState.paused
    
    -- Show pause text effect
    gameState.pauseTextAlpha = 1.0
    gameState.pauseTextTimer = 0
end

function gameState.isPaused()
    return gameState.paused
end

function gameState.drawPauseOverlay(fonts)
    if not gameState.paused then
        return
    end
    
    -- Semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Pause text
    love.graphics.setFont(fonts.extraLarge)
    love.graphics.setColor(1, 1, 1, 0.8)
    local pauseText = "GAME PAUSED"
    local textWidth = fonts.extraLarge:getWidth(pauseText)
    local textHeight = fonts.extraLarge:getHeight()
    
    love.graphics.print(pauseText, 
                      love.graphics.getWidth()/2 - textWidth/2, 
                      love.graphics.getHeight()/2 - textHeight - 40)
    
    -- Instructions
    love.graphics.setFont(fonts.large)
    love.graphics.setColor(1, 1, 1, 0.7)
    local instructText = "Press ESC to resume"
    local instructWidth = fonts.large:getWidth(instructText)
    
    love.graphics.print(instructText, 
                      love.graphics.getWidth()/2 - instructWidth/2, 
                      love.graphics.getHeight()/2 + 20)
end

return gameState