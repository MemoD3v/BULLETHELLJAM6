local game = require("modules.init")
local moonshine = require("libraries.moonshine")

effect = moonshine(moonshine.effects.filmgrain)
    .chain(moonshine.effects.vignette)
    .chain(moonshine.effects.scanlines)
    .chain(moonshine.effects.chromasep)

    effect.vignette.opacity = 0.55
    effect.filmgrain.size = 3
    effect.scanlines.opacity = 0.2
    effect.chromasep.radius = 1.5

function love.load()
    game.load()
end

function love.update(dt)
    game.update(dt)
end

function love.draw()
    effect(function()
        game.draw()
    end)
end

function love.mousepressed(x, y, button)
    game.mousepressed(x, y, button)
end

function love.keypressed(key)
    game.keypressed(key)
end

function love.resize(w, h)
    game.resize(w, h)
end

