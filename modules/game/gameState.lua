local gameState = {}

gameState.gameOver = false
gameState.score = 0
gameState.checkpointReached = false

function gameState.update(dt)
    -- Any global game state updates
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

function gameState.reset()
    gameState.gameOver = false
    gameState.score = 0
    gameState.checkpointReached = false
end

return gameState