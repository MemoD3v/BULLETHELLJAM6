local background = {}

background.active = false

function background.init()
    -- Configuration with default values
    background.config = {
        particleCount = 150,
        baseSpeed = 50,
        speedVariation = 0.5,
        minSize = 1,
        maxSize = 3,
        sizeVariation = 0.3,

        colors = {
            {0.95, 0.34, 0.60, 0.8},
            {0.30, 0.65, 0.99, 0.8},
            {0.99, 0.80, 0.30, 0.8},
            {0.50, 0.99, 0.60, 0.8}
        },
        colorVariation = 0.1,
        backgroundColor = {0.08, 0.08, 0.12, 1},
        gradientBackground = false,
        gradientColors = {{0.1, 0.1, 0.2, 1}, {0.05, 0.05, 0.1, 1}},

        movementType = "flow",
        flowDirection = {x = 1, y = 0.5},
        swirlCenter = {x = 0.5, y = 0.5},
        swirlStrength = 0.5,
        noiseScale = 0.01,
        noiseSpeed = 1,
        orbitRadius = 100,
        orbitSpeed = 0.5,

        enableConnections = true,
        connectionDistance = 100,
        connectionColor = {1, 1, 1, 0.1},
        connectionWidth = 1.5,
        maxConnections = 6,

        enableFadeEdges = true,
        fadeEdgeDistance = 50,
        enableTwinkle = true,
        twinkleSpeed = 0.5,
        enablePulse = true,
        pulseSpeed = 1,
        enableTrails = true,
        trailOpacity = 0.4,
        trailFrames = 10,
        enableShapes = true,
        shapeTypes = {"circle", "square", "triangle"},

        connectionOptimization = true
    }

    background.particles = {}
    background.trails = {}
    background.time = 0
    background.noiseOffset = 0
    background.screenWidth, background.screenHeight = love.graphics.getDimensions()
    background:_resetParticles()
end

function background:_resetParticles()
    background.particles = {}
    background.trails = {}

    for i = 1, background.config.particleCount do
        local baseColor = background.config.colors[math.random(#background.config.colors)]
        local colorVariation = background.config.colorVariation
        local color = background.active and {
            math.min(1, math.max(0, baseColor[1] + (math.random() * 2 - 1) * colorVariation)),
            math.min(1, math.max(0, baseColor[2] + (math.random() * 2 - 1) * colorVariation)),
            math.min(1, math.max(0, baseColor[3] + (math.random() * 2 - 1) * colorVariation)),
            baseColor[4]
        } or {1, 1, 1, 0.2}

        table.insert(background.particles, {
            x = math.random() * background.screenWidth,
            y = math.random() * background.screenHeight,
            size = math.random() * (background.config.maxSize - background.config.minSize) + background.config.minSize,
            baseSize = math.random() * (background.config.maxSize - background.config.minSize) + background.config.minSize,
            color = color,
            speed = background.config.baseSpeed * (1 + (math.random() * 2 - 1) * background.config.speedVariation),
            angle = math.random() * math.pi * 2,
            baseAlpha = color[4],
            twinklePhase = math.random() * math.pi * 2,
            pulsePhase = math.random() * math.pi * 2,
            noiseOffsetX = math.random() * 1000,
            noiseOffsetY = math.random() * 1000,
            orbitPhase = math.random() * math.pi * 2,
            shape = background.config.shapeTypes[math.random(#background.config.shapeTypes)],
            rotation = math.random() * math.pi * 2,
            rotationSpeed = (math.random() * 2 - 1) * 0.1
        })
    end
end

function background.activate()
    background.active = true -- Set before reset
    background:_resetParticles()
end

function background.deactivate()
    background.active = false -- Set before reset
    background:_resetParticles()
end


function background.update(dt)
    background.time = background.time + dt
    background.noiseOffset = background.noiseOffset + dt * background.config.noiseSpeed

    if background.config.enableTrails then
        for _, p in ipairs(background.particles) do
            table.insert(background.trails, {
                x = p.x, y = p.y,
                size = p.size,
                color = {p.color[1], p.color[2], p.color[3], background.config.trailOpacity},
                time = 0,
                shape = p.shape,
                rotation = p.rotation
            })
        end

        for i = #background.trails, 1, -1 do
            background.trails[i].time = background.trails[i].time + dt
            if background.trails[i].time > background.config.trailFrames * dt then
                table.remove(background.trails, i)
            end
        end
    end

    for _, p in ipairs(background.particles) do
        if background.config.movementType == "flow" then
            p.angle = math.atan2(background.config.flowDirection.y, background.config.flowDirection.x)
        elseif background.config.movementType == "swirl" then
            local cx = background.config.swirlCenter.x * background.screenWidth
            local cy = background.config.swirlCenter.y * background.screenHeight
            local dx = p.x - cx
            local dy = p.y - cy
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist > 10 then
                p.angle = math.atan2(dy, dx) + math.pi/2 * background.config.swirlStrength
                p.x = p.x - dx * 0.0001 * p.speed
                p.y = p.y - dy * 0.0001 * p.speed
            end
        elseif background.config.movementType == "random" then
            if math.random() < 0.02 then
                p.angle = math.random() * math.pi * 2
            end
        elseif background.config.movementType == "bounce" then
            if p.x <= 0 or p.x >= background.screenWidth then p.angle = math.pi - p.angle end
            if p.y <= 0 or p.y >= background.screenHeight then p.angle = -p.angle end
        elseif background.config.movementType == "noise" then
            local nx = love.math.noise(p.noiseOffsetX + background.time * background.config.noiseScale, background.noiseOffset)
            local ny = love.math.noise(p.noiseOffsetY + background.time * background.config.noiseScale, background.noiseOffset)
            p.angle = math.atan2(ny * 2 - 1, nx * 2 - 1)
        elseif background.config.movementType == "orbit" then
            p.orbitPhase = p.orbitPhase + dt * background.config.orbitSpeed
            local cx = background.config.swirlCenter.x * background.screenWidth
            local cy = background.config.swirlCenter.y * background.screenHeight
            local radius = background.config.orbitRadius * (0.5 + 0.5 * love.math.noise(p.noiseOffsetX, background.time))
            p.x = cx + math.cos(p.orbitPhase) * radius
            p.y = cy + math.sin(p.orbitPhase) * radius
        end

        if background.config.movementType ~= "orbit" then
            p.x = p.x + math.cos(p.angle) * p.speed * dt
            p.y = p.y + math.sin(p.angle) * p.speed * dt
        end

        if p.x < 0 then p.x = background.screenWidth end
        if p.x > background.screenWidth then p.x = 0 end
        if p.y < 0 then p.y = background.screenHeight end
        if p.y > background.screenHeight then p.y = 0 end

        p.rotation = p.rotation + p.rotationSpeed * dt

        if background.config.enableTwinkle then
            p.twinklePhase = p.twinklePhase + dt * background.config.twinkleSpeed
            local twinkle = (math.sin(p.twinklePhase) * 0.2 + 0.8)
            p.color[4] = p.baseAlpha * twinkle
        end

        if background.config.enablePulse then
            p.pulsePhase = p.pulsePhase + dt * background.config.pulseSpeed
            local pulse = (math.sin(p.pulsePhase) * background.config.sizeVariation + 1)
            p.size = p.baseSize * pulse
        end
    end
end

function background:_drawParticle(x, y, size, color, shape, rotation)
    love.graphics.setColor(color)
    if shape == "circle" then
        love.graphics.circle("fill", x, y, size)
    elseif shape == "square" then
        love.graphics.push()
        love.graphics.translate(x, y)
        love.graphics.rotate(rotation)
        love.graphics.rectangle("fill", -size, -size, size*2, size*2)
        love.graphics.pop()
    elseif shape == "triangle" then
        love.graphics.push()
        love.graphics.translate(x, y)
        love.graphics.rotate(rotation)
        local h = size * math.sqrt(3)
        love.graphics.polygon("fill", 0, -h/2, size, h/2, -size, h/2)
        love.graphics.pop()
    end
end

function background:_drawGradientBackground()
    local c1 = background.config.gradientColors[1]
    local c2 = background.config.gradientColors[2]
    love.graphics.setColor(c1)
    love.graphics.rectangle("fill", 0, 0, background.screenWidth, background.screenHeight)

    local mesh = love.graphics.newMesh({
        {0, 0, c1[1], c1[2], c1[3], c1[4]},
        {background.screenWidth, 0, c1[1], c1[2], c1[3], c1[4]},
        {background.screenWidth, background.screenHeight, c2[1], c2[2], c2[3], c2[4]},
        {0, background.screenHeight, c2[1], c2[2], c2[3], c2[4]}
    }, "fan", "static")

    love.graphics.draw(mesh)
end

function background:_drawConnections()
    if not background.config.enableConnections then return end
    love.graphics.setLineWidth(background.config.connectionWidth)

    for i = 1, #background.particles do
        local p1 = background.particles[i]
        local connectionsCount = 0

        for j = i + 1, #background.particles do
            if background.config.connectionOptimization and connectionsCount >= background.config.maxConnections then
                break
            end

            local p2 = background.particles[j]
            local dx = p1.x - p2.x
            local dy = p1.y - p2.y
            local distSq = dx*dx + dy*dy

            if distSq < background.config.connectionDistance * background.config.connectionDistance then
                local dist = math.sqrt(distSq)
                local alpha = (1 - dist / background.config.connectionDistance) * background.config.connectionColor[4]
                love.graphics.setColor(background.config.connectionColor[1], background.config.connectionColor[2],
                    background.config.connectionColor[3], alpha)
                love.graphics.line(p1.x, p1.y, p2.x, p2.y)
                connectionsCount = connectionsCount + 1
            end
        end
    end
end

function background.draw()
    if background.config.gradientBackground then
        background:_drawGradientBackground()
    else
        love.graphics.setColor(background.config.backgroundColor)
        love.graphics.rectangle("fill", 0, 0, background.screenWidth, background.screenHeight)
    end

    if background.config.enableTrails then
        for _, t in ipairs(background.trails) do
            local alpha = t.color[4] * (1 - t.time / (background.config.trailFrames * 0.016))
            background:_drawParticle(t.x, t.y, t.size,
                {t.color[1], t.color[2], t.color[3], alpha},
                t.shape, t.rotation)
        end
    end

    background:_drawConnections()

    for _, p in ipairs(background.particles) do
        local alpha = p.color[4]

        if background.config.enableFadeEdges then
            local edgeX = math.min(p.x, background.screenWidth - p.x)
            local edgeY = math.min(p.y, background.screenHeight - p.y)
            local edgeDist = math.min(edgeX, edgeY)
            if edgeDist < background.config.fadeEdgeDistance then
                alpha = alpha * (edgeDist / background.config.fadeEdgeDistance)
            end
        end

        background:_drawParticle(p.x, p.y, p.size,
            {p.color[1], p.color[2], p.color[3], alpha},
            p.shape, p.rotation)
    end
end

function background.resize(w, h)
    background.screenWidth = w
    background.screenHeight = h
end

return background
