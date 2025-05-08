local config = {}

-- Grid configuration
config.gridSize = 7
config.cellSize = 60
config.gridColor = {0.5, 0.5, 0.5}

-- Player configuration
config.playerSize = 50
config.playerColor = {1, 1, 1}
config.moveCooldown = 0.15
config.playerMaxHealth = 100
config.playerHealthRegenRate = 0.5 -- Health regeneration per second when not taking damage
config.playerDamageInvulnerabilityTime = 1.0 -- Seconds of invulnerability after taking damage

-- Bullet configuration
config.bulletSpeed = 400
config.bulletWidth = 12
config.bulletHeight = 4
config.bulletColor = {1, 1, 1}
config.bulletDamage = 25

-- Enemy bullet configuration
config.enemyBulletSpeed = 200
config.enemyBulletSize = 6
config.enemyBulletDamage = 10
config.enemyFireRate = 1.5 -- Default fire rate in seconds

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
        score = 10,
        tier = 1,
        fireRate = 2.5,
        bulletSpeed = 150,
        bulletColor = {1, 0.2, 0.2},
        bulletSize = 5,
        bulletPattern = "single"
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
        score = 20,
        tier = 2,
        fireRate = 2.2,
        bulletSpeed = 180,
        bulletColor = {0.2, 0.5, 1},
        bulletSize = 6,
        bulletPattern = "single"
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
        score = 30,
        tier = 3,
        fireRate = 2.0,
        bulletSpeed = 200,
        bulletColor = {1, 0.5, 0.2},
        bulletSize = 7,
        bulletPattern = "double"
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
        score = 40,
        tier = 4,
        fireRate = 1.8,
        bulletSpeed = 220,
        bulletColor = {0.7, 0.2, 1},
        bulletSize = 8,
        bulletPattern = "triple"
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
        score = 50,
        tier = 5,
        fireRate = 1.5,
        bulletSpeed = 250,
        bulletColor = {0.2, 1, 0.5},
        bulletSize = 9,
        bulletPattern = "spread"
    },
    {
        name = "Game Owner", -- Only appears in phase 2
        color = {1, 0.3, 0},
        health = 300,
        maxHealth = 300,
        speed = 0.7,
        unlockAt = 5, -- Phase 2, checkpoint 0
        size = 55,
        damage = 40,
        score = 100,
        tier = 6,
        fireRate = 1.2,
        bulletSpeed = 270,
        bulletColor = {1, 0.5, 0},
        bulletSize = 10,
        bulletPattern = "wave"
    },
    {
        name = "Root Admin", -- Only appears in later part of phase 2
        color = {1, 0, 0},
        health = 400,
        maxHealth = 400,
        speed = 0.9,
        unlockAt = 7, -- Phase 2, checkpoint 2
        size = 60,
        damage = 50,
        score = 200,
        tier = 7,
        fireRate = 1.0,
        bulletSpeed = 300,
        bulletColor = {1, 0, 0},
        bulletSize = 12,
        bulletPattern = "burst"
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