function love.conf(t)
    t.identity = "bullethelljam"            -- The name of the save directory
    t.version = "11.4"                      -- The LÖVE version this game was made for
    t.console = false                       -- Attach a console (boolean, Windows only)
    t.accelerometerjoystick = false         -- Enable the accelerometer on iOS and Android by exposing it as a Joystick

    -- Window settings
    t.window.title = "Bullet Hell Jam 6"    -- The window title
    t.window.icon = nil                     -- Filepath to an image to use as the window's icon
    t.window.width = 800                    -- The window width
    t.window.height = 600                   -- The window height
    t.window.resizable = true               -- Let the window be user-resizable
    t.window.minwidth = 640                 -- Minimum window width if the window is resizable
    t.window.minheight = 480                -- Minimum window height if the window is resizable
    t.window.fullscreen = false             -- Enable fullscreen
    t.window.vsync = 1                      -- Vertical sync mode

    -- Modules settings - These settings disable modules we aren't using for web compatibility
    t.modules.audio = true                  -- Enable the audio module
    t.modules.data = true                   -- Enable the data module
    t.modules.event = true                  -- Enable the event module
    t.modules.font = true                   -- Enable the font module
    t.modules.graphics = true               -- Enable the graphics module
    t.modules.image = true                  -- Enable the image module
    t.modules.joystick = false              -- Disable the joystick module
    t.modules.keyboard = true               -- Enable the keyboard module
    t.modules.math = true                   -- Enable the math module
    t.modules.mouse = true                  -- Enable the mouse module
    t.modules.physics = false               -- Disable the physics module
    t.modules.sound = true                  -- Enable the sound module
    t.modules.system = true                 -- Enable the system module
    t.modules.thread = false                -- Disable the thread module
    t.modules.timer = true                  -- Enable the timer module
    t.modules.touch = true                  -- Enable the touch module
    t.modules.video = false                 -- Disable the video module
    t.modules.window = true                 -- Enable the window module
end
