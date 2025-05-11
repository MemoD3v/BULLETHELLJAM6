local gameModes = {}

-- Game modes configuration
gameModes.modes = {
    {
        id = "default",
        name = "Default",
        description = "Standard gameplay experience",
        startingHealth = 100,
        enemySpawnMultiplier = 1.0,
        scoreMultiplier = 1.0,
        hasEndCondition = true,
        vampiricEffect = false,
        isRogueLike = false
    },
    {
        id = "endless",
        name = "Endless",
        description = "Play until you die - no victory condition",
        startingHealth = 120,
        enemySpawnMultiplier = 1.2,
        scoreMultiplier = 1.5,
        hasEndCondition = false,
        vampiricEffect = false,
        isRogueLike = false
    },
    {
        id = "madness",
        name = "Madness",
        description = "3x more enemies - can you survive?",
        startingHealth = 150,
        enemySpawnMultiplier = 3.0,
        scoreMultiplier = 2.0,
        hasEndCondition = true,
        vampiricEffect = false,
        isRogueLike = false
    },
    {
        id = "vampire",
        name = "Vampire",
        description = "Killing enemies restores health",
        startingHealth = 80,
        enemySpawnMultiplier = 1.5,
        scoreMultiplier = 1.2,
        hasEndCondition = true,
        vampiricEffect = true,
        healthPerKill = 2, -- Health restored per enemy killed
        isRogueLike = false
    },
    {
        id = "roguelike",
        name = "RogueLike",
        description = "Free movement with the engine following you",
        startingHealth = 110,
        enemySpawnMultiplier = 1.2,
        scoreMultiplier = 1.3,
        hasEndCondition = true,
        vampiricEffect = false,
        isRogueLike = true -- Flag to enable special RogueLike behavior
    }
}

-- Current selected game mode (default to first mode)
gameModes.currentMode = gameModes.modes[1]

-- Initialize game modes
function gameModes.init()
    -- Nothing special needed for initialization
end

-- Get current game mode
function gameModes.getCurrentMode()
    return gameModes.currentMode
end

-- Set current game mode by ID
function gameModes.setModeById(modeId)
    for _, mode in ipairs(gameModes.modes) do
        if mode.id == modeId then
            gameModes.currentMode = mode
            return true
        end
    end
    return false
end

-- Get all available game modes
function gameModes.getAllModes()
    return gameModes.modes
end

-- Apply vampire effect if applicable
function gameModes.applyVampireEffect(player)
    if gameModes.currentMode.vampiricEffect and gameModes.currentMode.healthPerKill then
        player.addHealth(gameModes.currentMode.healthPerKill)
        return true
    end
    return false
end

-- Get enemy spawn multiplier for current mode
function gameModes.getEnemySpawnMultiplier()
    return gameModes.currentMode.enemySpawnMultiplier or 1.0
end

-- Get score multiplier for current mode
function gameModes.getScoreMultiplier()
    return gameModes.currentMode.scoreMultiplier or 1.0
end

-- Does the current mode have an end condition?
function gameModes.hasEndCondition()
    return gameModes.currentMode.hasEndCondition
end

-- Get starting health for current mode
function gameModes.getStartingHealth()
    return gameModes.currentMode.startingHealth or 100
end

-- Check if current mode has vampiric effect
function gameModes.hasVampiricEffect()
    return gameModes.currentMode.vampiricEffect or false
end

-- Get health per kill for vampiric effect
function gameModes.getHealthPerKill()
    return gameModes.currentMode.healthPerKill or 0
end

-- Check if current mode is RogueLike
function gameModes.isRogueLike()
    return gameModes.currentMode.isRogueLike or false
end

return gameModes
