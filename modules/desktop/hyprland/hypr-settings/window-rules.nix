{
  exo.mods.desktop = {
    forte.hyprland.lua.window-rules = # lua
      ''
        --         ▀             █                                ▀█
        -- █   █  ▀█   █▀▀▀▄ ▄▀▀▀█ ▄▀▀▀▄ █   █       █▄▀▀▀ █   █   █   ▄▀▀▀▄ ▄▀▀▀▀
        -- █ █ █   █   █   █ █   █ █   █ █ █ █ ▀▀▀▀▀ █     █   █   █   █▀▀▀▀  ▀▀▀▄
        -- ▀▄█▄▀  ▄█▄  █   █ ▀▄▄▄█ ▀▄▄▄▀ ▀▄█▄▀       █     ▀▄▄▄█   ▀▄▄ ▀▄▄▄▄ ▄▄▄▄▀

        hl.window_rule({
          -- Fix some dragging issues with XWayland
          name     = "fix-xwayland-drags",
          match    = {
            class      = "^$",
            title      = "^$",
            xwayland   = true,
            float      = true,
            fullscreen = false,
            pin        = false,
          },

          no_focus = true,
        })

        hl.window_rule({
          name  = "screenshare portal",
          match = {
            class = "hyprland-share-picker",
          },
          size  = { 700, 350 },
          float = true,
        })

        -- Float browser popups that only get their real title after the window opens.
        -- Window rules are matched at open time, when a Bitwarden
        -- is still an ordinary untitled browser window, so they cannot catch it:
        -- https://github.com/hyprwm/Hyprland/issues/3835
        -- Sizes are percentages of the monitor
        local popup_rules = {
          -- Bitwarden vault prompt.
          {
            width = 14,
            height = 50,
            patterns = {
              "%(Bitwarden.*Password Manager%) %- Bitwarden",
              "^Bitwarden$",
            }
          },
        }

        hl.on("window.title", function(window)
          if window.floating then
            return
          end

          local title = window.title or ""

          for _, rule in ipairs(popup_rules) do
            for _, pattern in ipairs(rule.patterns) do
              if title:match(pattern) then
                local monitor = window.monitor or hl.get_active_monitor()
                if not monitor then
                  return
                end

                -- monitor.width/height are mode pixels, window geometry is logical.
                local target = "address:" .. window.address
                hl.dispatch(hl.dsp.window.float({ action = "on", window = target }))
                hl.dispatch(hl.dsp.window.resize({
                  window = target,
                  x = math.floor(monitor.width / monitor.scale * rule.width / 100),
                  y = math.floor(monitor.height / monitor.scale * rule.height / 100),
                  relative = false,
                }))
                hl.dispatch(hl.dsp.window.center({ window = target }))
                return
              end
            end
          end
        end)
      '';
  };
}
