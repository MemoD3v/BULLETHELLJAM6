local camera = {}

-- Define shake properties as direct properties of camera
camera.intensity = 0
camera.timer = 0
camera.duration = 0
camera.offsetX = 0
camera.offsetY = 0

function camera.update(dt, instabilityLevel)
    if camera.timer > 0 then
        camera.timer = camera.timer - dt
        local progress = camera.timer / camera.duration
        local intensity = camera.intensity * progress * (1 + instabilityLevel * 0.5)
        camera.offsetX = (love.math.random() * 2 - 1) * intensity
        camera.offsetY = (love.math.random() * 2 - 1) * intensity
    else
        camera.offsetX = 0
        camera.offsetY = 0
    end
end

function camera.shake(intensity, duration)
    camera.intensity = intensity
    camera.duration = duration
    camera.timer = duration
end

function camera.getOffset()
    return camera.offsetX, camera.offsetY
end

function camera.reset()
    camera.intensity = 0
    camera.timer = 0
    camera.duration = 0
    camera.offsetX = 0
    camera.offsetY = 0
end

return camera