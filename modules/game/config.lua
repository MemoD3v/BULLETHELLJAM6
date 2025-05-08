local config = {}

-- Grid configuration
config.gridSize = 7
config.cellSize = 60
config.gridColor = {0.5, 0.5, 0.5}

-- Player configuration
config.playerSize = 50
config.playerColor = {1, 1, 1}
config.moveCooldown = 0.15

-- Bullet configuration
config.bulletSpeed = 400
config.bulletWidth = 12
config.bulletHeight = 4
config.bulletColor = {1, 1, 1}
config.bulletDamage = 25

-- Enemy configuration
config.enemySpawnInterval = 3.0
config.enemyTypes = {
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

-- Engine configuration
config.engineMaxEnemiesBeforeGameOver = 3
config.engineUnstableAmplitude = 2

-- Loading bar configuration
config.loadingBarColor = {0.2, 0.6, 1}
config.loadingBarBgColor = {0.1, 0.1, 0.1}
config.loadingBarText = "PAYLOAD"
config.loadingBarHeight = 20

return config