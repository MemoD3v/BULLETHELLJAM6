local game = require("modules.init")
local moonshine = require("libraries.moonshine")
local bg = require("modules.game.background")
local mainMenu = require("modules.game.mainMenu")

effect = moonshine(moonshine.effects.filmgrain)
    .chain(moonshine.effects.vignette)
    .chain(moonshine.effects.scanlines)
    .chain(moonshine.effects.chromasep)

    effect.vignette.opacity = 0.55
    effect.filmgrain.size = 3
    effect.scanlines.opacity = 0.2
    effect.chromasep.radius = 1.5

function love.load()
    -- Removed console opening call that was causing errors
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
    -- Fix: Combine both mousepressed handlers to avoid conflicts
    print("Main mousepressed called: " .. button)
    
    -- Check if menu is active first
    if mainMenu.isActive() then
        mainMenu.mousepressed(x, y, button)
    else
        -- Forward to game module for gameplay
        game.mousepressed(x, y, button)
    end
end

function love.keypressed(key)
    -- First check if menu is active
    if mainMenu.isActive() then
        mainMenu.keypressed(key)
        return
    end
    
    -- Now check if engine should handle this key press
    local engine = require("modules.game.engine")
    if engine.keypressed(key) then
        -- Engine consumed the key press, don't pass to other handlers
        return
    end
    
    -- Otherwise, pass to game module for normal gameplay
    game.keypressed(key)
end

function love.textinput(text)
    game.textinput(text)
end

function love.resize(w, h)
    game.resize(w, h)
end
