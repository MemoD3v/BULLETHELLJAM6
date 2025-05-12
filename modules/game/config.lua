local config = {}

-- Grid configuration
config.gridSize = 7
config.cellSize = 60
config.gridColor = {0.5, 0.5, 0.5}

-- Player configuration
config.playerSize = 50
config.playerColor = {1, 1, 1}
config.moveCooldown = 0.15
config.playerMaxHealth = 120  -- Increased from 100
config.playerHealthRegenRate = 0.8  -- Increased from 0.5
config.playerDamageInvulnerabilityTime = 1.5  -- Increased from 1.0

-- Bullet configuration
config.bulletSpeed = 450  -- Increased from 400
config.bulletWidth = 12
config.bulletHeight = 4
config.bulletColor = {1, 1, 1}
config.bulletDamage = 30  -- Increased from 25

-- Enemy bullet configuration
config.enemyBulletSpeed = 180  -- Reduced from 200
config.enemyBulletSize = 5    -- Reduced from 6
config.enemyBulletDamage = 8  -- Reduced from 10
config.enemyFireRate = 1.8    -- Increased from 1.5 (slower firing)

-- Enemy configuration
config.enemySpawnInterval = 3.5  -- Increased from 3.0 (slower spawn rate)
config.enemyTypes = {
    {
        name = "Anti-Cheat",
        color = {0.8, 0.2, 0.2},
        health = 50,
        maxHealth = 50,
        speed = 0.5,
        unlockAt = 0,        -- Available from 0% progress
        unlockAtPercent = 0.0, -- 0% loading bar progress
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
        unlockAt = 1,        -- For backwards compatibility
        unlockAtPercent = 0.2, -- 20% loading bar progress
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
        health = 100,
        maxHealth = 100,
        speed = 0.5,
        unlockAt = 2,        -- For backwards compatibility
        unlockAtPercent = 0.4, -- 40% loading bar progress
        size = 40,
        damage = 15,
        score = 35,
        tier = 3,
        fireRate = 2.2,
        bulletSpeed = 180,
        bulletColor = {1, 0.5, 0.2},
        bulletSize = 7,
        bulletPattern = "double"
    },
    {
        name = "Admins",
        color = {0.5, 0.2, 0.8},
        health = 130,
        maxHealth = 130,
        speed = 0.7,
        unlockAt = 3,        -- For backwards compatibility
        unlockAtPercent = 0.6, -- 60% loading bar progress
        size = 45,
        damage = 20,
        score = 45,
        tier = 4,
        fireRate = 2.0,
        bulletSpeed = 200,
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
        unlockAt = 4,        -- For backwards compatibility
        unlockAtPercent = 0.8, -- 80% loading bar progress
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
        name = "Game Owner",
        color = {1, 0.3, 0},
        health = 300,
        maxHealth = 300,
        speed = 0.7,
        unlockAt = 5,        -- For backwards compatibility
        unlockAtPercent = 1.0, -- 100% loading bar progress
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
        name = "Root Admin", -- Reserved for future use (beyond 100%)
        color = {1, 0, 0},
        health = 400,
        maxHealth = 400,
        speed = 0.9,
        unlockAt = 7,        -- For backwards compatibility
        unlockAtPercent = 1.1, -- Beyond 100% (essentially locked until further implementation)
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
config.engineMaxEnemiesBeforeGameOver = 4  -- Increased from 3
config.engineUnstableAmplitude = 2

-- Loading bar configuration
config.loadingBarColor = {0.2, 0.6, 1}
config.loadingBarBgColor = {0.1, 0.1, 0.1}
config.loadingBarText = "PAYLOAD"
config.loadingBarHeight = 20

return config