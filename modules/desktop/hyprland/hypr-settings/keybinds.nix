{
  exo.mods.desktop =
    {
      pkgs,
      scheme,
      lib,
      ...
    }:
    {
      forte.hyprland.lua.keybinds =
        let
          input-source = pkgs.writeShellApplication {
            name = "input-source";
            derivationArgs = {
              allowSubstitutes = false;
              preferLocalBuild = true;
            };
            runtimeInputs = [
              pkgs.gum
              pkgs.ddcutil
            ];
            text = ''
              CHOICE=$(gum choose --cursor=" " --cursor.foreground="#fff" --header="" --no-show-help 'DisplayPort-1' 'HDMI-1' 'HDMI-2')

              if [[ -z $CHOICE ]]; then
                exit 0
              fi

              gum confirm --no-show-help --selected.background="${scheme.base0D}" --prompt.foreground="${scheme.base0D}" "$CHOICE?" || exit 0

              case $CHOICE in
                "DisplayPort-1") ddcutil setvcp 60 0x0f ;;
                "HDMI-1") ddcutil setvcp 60 0x11 ;;
                "HDMI-2") ddcutil setvcp 60 0x12 ;;
              esac
            '';

          };
        in
        # lua
        ''
          hl.bind("SUPER + ALT + D", function()
              local win = hl.get_window("class:input-source")
              if win then
                  hl.dispatch(hl.dsp.window.close({ window = win }))
              else
                  hl.dispatch(hl.dsp.exec_cmd("kitty --class input-source -e ${lib.getExe input-source}", {
                      border_size  = 2,
                      pin          = true,
                      float        = true,
                      center       = true,
                      size         = { 184,90 },
                  }))
              end
          end)
          -- █                █       ▀             █
          -- █ ▄▀ ▄▀▀▀▄ █   █ █▀▀▀▄  ▀█   █▀▀▀▄ ▄▀▀▀█ ▄▀▀▀▀
          -- ██   █▀▀▀▀ █   █ █   █   █   █   █ █   █  ▀▀▀▄
          -- █ ▀▄ ▀▄▄▄▄ ▀▄▄▄█ █▄▄▄▀  ▄█▄  █   █ ▀▄▄▄█ ▄▄▄▄▀
          --             ▄▄▄▀
          -- Example binds, see https://wiki.hypr.land/Configuring/Basics/Binds/ for more
          hl.bind("SUPER + Q", hl.dsp.window.close())

          -- screenshot
          hl.permission({ binary = "${pkgs.grim}/bin/grim", type = "screencopy", mode = "allow" })
          hl.permission({ binary = "${pkgs.wayfreeze}/bin/wayfreeze", type = "screencopy", mode = "allow" })
          hl.bind("Print", hl.dsp.exec_raw("${pkgs.wayfreeze}/bin/wayfreeze --after-freeze-cmd '${pkgs.grim}/bin/grim -g \"$(${pkgs.slurp}/bin/slurp)\" - | wl-copy; killall wayfreeze'"))

          -- cycle keyboard lang layout
          hl.bind("CTRL + Space", hl.dsp.exec_cmd("hyprctl switchxkblayout all next"))

          -- fullscreen keybind
          hl.bind("SUPER + M", hl.dsp.window.fullscreen())

          -- cycle between floating and tiled
          hl.bind("ALT + TAB", function()
              local window = hl.get_active_window()
              if not window then return end

              if window.floating then
                  hl.dispatch(hl.dsp.window.cycle_next({ next = true, tiled = true, floating = false }))
              else
                  hl.dispatch(hl.dsp.window.cycle_next({ next = true, tiled = false, floating = true }))
              end
          end)

          -- toggle floating
          hl.bind("SUPER + SHIFT + W", function()
            local win = hl.get_active_window()
            if not win then return end

            if win.floating then
              hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
            else
              hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
              hl.dispatch(hl.dsp.window.resize({ x = 2100, y = 1200, relative = false }))
              hl.dispatch(hl.dsp.window.center())
            end
          end)

          -- Move focus with SUPER + arrow keys
          hl.bind("SUPER + left", hl.dsp.focus({ direction = "left" }))
          hl.bind("SUPER + right", hl.dsp.focus({ direction = "right" }))
          hl.bind("SUPER + up", hl.dsp.focus({ direction = "up" }))
          hl.bind("SUPER + down", hl.dsp.focus({ direction = "down" }))

          -- focus through existing windows with SUPER + scroll
          hl.bind("SUPER + mouse_down", hl.dsp.focus({ direction = "right" }))
          hl.bind("SUPER + mouse_up", hl.dsp.focus({ direction = "left" }))

          -- Move/resize windows with SUPER + LMB/RMB and dragging
          hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
          hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

          -- zoom
          local function toggle_zoom()
            local current = hl.get_config("cursor.zoom_factor")
            local new_zoom = (current == 1) and 3.5 or 1
            hl.config({ cursor = { zoom_factor = new_zoom } })
          end
          hl.bind("SUPER + Z", toggle_zoom)

          --                          ▀█    ▀█     ▀                      █       ▀             █
          -- ▄▀▀▀▀ ▄▀▀▀▄ █▄▀▀▀ ▄▀▀▀▄   █     █    ▀█   █▀▀▀▄ ▄▀▀▀█        █▀▀▀▄  ▀█   █▀▀▀▄ ▄▀▀▀█ ▄▀▀▀▀
          --  ▀▀▀▄ █     █     █   █   █     █     █   █   █ █   █        █   █   █   █   █ █   █  ▀▀▀▄
          -- ▄▄▄▄▀ ▀▄▄▄▀ █     ▀▄▄▄▀   ▀▄▄   ▀▄▄  ▄█▄  █   █ ▀▄▄▄█        █▄▄▄▀  ▄█▄  █   █ ▀▄▄▄█ ▄▄▄▄▀
          --                                                  ▄▄▄▀
          local function scrolling_only(fn)
            return function()
              local workspace = hl.get_active_workspace()
              if workspace and workspace.tiled_layout == "scrolling" then
                fn()
              end
            end
          end

          local function scrolling_binds(key, action)
            local fn = type(action) == "function" and action or function() hl.dispatch(action) end
            hl.bind(key, scrolling_only(fn))
          end

          scrolling_binds("SUPER + CTRL + left", hl.dsp.layout("swapcol l"))
          scrolling_binds("SUPER + CTRL + right", hl.dsp.layout("swapcol r"))
          scrolling_binds("SUPER + bracketright", function()
              hl.dispatch(hl.dsp.layout("consume_or_expel next"))
              hl.dispatch(hl.dsp.layout("colresize 0.333"))
          end)

          scrolling_binds("SUPER + bracketleft", function()
              hl.dispatch(hl.dsp.layout("consume_or_expel prev"))
              hl.dispatch(hl.dsp.layout("colresize 0.333"))
          end)
          hl.bind("SUPER + F", function()
              local ws = hl.get_active_workspace()

              if ws and (ws.name == "2" or ws.name == "3") and ws.windows < 4 then
                  hl.dispatch(hl.dsp.layout("fit all"))
              else
                  hl.dispatch(hl.dsp.layout("fit active"))
              end
          end)

          scrolling_binds("SUPER + R", function()
            hl.dispatch(hl.dsp.layout("colresize +conf"))
          end)
          scrolling_binds("SUPER + E", function()
            hl.dispatch(hl.dsp.layout("colresize -conf"))
          end)

          scrolling_binds("SUPER + C", function()
            local prev = hl.get_config("scrolling.focus_fit_method")

            hl.config({ scrolling = { focus_fit_method = 0 } })
            hl.dispatch(hl.dsp.layout("center"))
            hl.config({ scrolling = { focus_fit_method = prev } })
          end)
        '';
    };
}
