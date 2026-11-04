{
  exo.mods.desktop = {
    forte.hyprland.lua.animations = # lua
      ''

        --               ▀                 █     ▀
        --  ▀▀▀▄ █▀▀▀▄  ▀█   █▀█▀▄  ▀▀▀▄  ▀█▀   ▀█   ▄▀▀▀▄ █▀▀▀▄ ▄▀▀▀▀
        -- ▄▀▀▀█ █   █   █   █ █ █ ▄▀▀▀█   █     █   █   █ █   █  ▀▀▀▄
        -- ▀▄▄▄█ █   █  ▄█▄  █ █ █ ▀▄▄▄█   ▀▄▄  ▄█▄  ▀▄▄▄▀ █   █ ▄▄▄▄▀

        -- Bezier curves
        hl.curve("myBezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
        hl.curve("linear", { type = "bezier", points = { { 0.0, 0.0 }, { 1.0, 1.0 } } })
        hl.curve("wind", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
        hl.curve("winIn", { type = "bezier", points = { { 0.1, 1.1 }, { 0.1, 1.1 } } })
        hl.curve("winOut", { type = "bezier", points = { { 0.3, -0.3 }, { 0, 1 } } })
        hl.curve("slow", { type = "bezier", points = { { 0, 0.85 }, { 0.3, 1 } } })
        hl.curve("overshot", { type = "bezier", points = { { 0.7, 0.6 }, { 0.1, 1.1 } } })
        hl.curve("bounce", { type = "bezier", points = { { 1.1, 1.6 }, { 0.1, 0.85 } } })
        hl.curve("slingshot", { type = "bezier", points = { { 1, -1 }, { 0.15, 1.25 } } })
        hl.curve("smoothOut", { type = "bezier", points = { { 0.36, 0 }, { 0.66, -0.56 } } })
        hl.curve("smoothIn", { type = "bezier", points = { { 0.25, 1 }, { 0.5, 1 } } })
        hl.curve("easeInSine", { type = "bezier", points = { { 0.005, 0.89 }, { 0.09, 0.91 } } })

        -- Animations
        hl.animation({ leaf = "windowsIn", enabled = true, speed = 3, bezier = "winIn", style = "gnomed" })
        hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "winOut", style = "gnomed" })
        hl.animation({ leaf = "windowsMove", enabled = true, speed = 3.5, bezier = "slow", style = "slide" })
        hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "linear" })
        hl.animation({ leaf = "fade", enabled = true, speed = 5, bezier = "overshot" })
        hl.animation({ leaf = "workspacesIn", enabled = true, speed = 3, bezier = "slow", style = "slidevert" })
        hl.animation({ leaf = "workspacesOut", enabled = true, speed = 3, bezier = "slow", style = "slidevert" })
        hl.animation({ leaf = "windows", enabled = true, speed = 3, bezier = "bounce", style = "popin" })
        hl.animation({ leaf = "specialWorkspaceIn",  enabled = true, speed = 4, bezier = "smoothIn", style = "slide left"  })
        hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 4, bezier = "smoothOut", style = "slide right" })
        hl.animation({ leaf = "layersIn", enabled = false, speed = 3, bezier = "smoothIn", style = "slide top" })
        hl.animation({ leaf = "layersOut", enabled = false, speed = 3, bezier = "wind", style = "slide top" })
        hl.animation({ leaf = "border", enabled = true, speed = 4, bezier = "easeInSine" })
      '';
  };
}
