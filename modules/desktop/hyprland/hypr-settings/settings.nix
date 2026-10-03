{
  exo.mods.desktop =
    {
      theme,
      config,
      scheme,
      ...
    }:
    {
      forte.hyprland.lua.settings = # lua
        ''
          hl.permission({ binary = "${config.forte.hyprland.portalPackage}/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", type = "screencopy", mode = "allow" })

          hl.on("hyprland.start", function()
            hl.dispatch(hl.dsp.exec_cmd("sleep 5 && wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.6"))
          end)

          --                                      ▀█
          -- ▄▀▀▀█ ▄▀▀▀▄ █▀▀▀▄ ▄▀▀▀▄ █▄▀▀▀  ▀▀▀▄   █
          -- █   █ █▀▀▀▀ █   █ █▀▀▀▀ █     ▄▀▀▀█   █
          -- ▀▄▄▄█ ▀▄▄▄▄ █   █ ▀▄▄▄▄ █     ▀▄▄▄█   ▀▄▄
          --  ▄▄▄▀

          hl.config({
            general = {
              no_focus_fallback = true,
              col         = {
                inactive_border = { colors = { "${if theme == "dark" then "#362D40" else scheme.base03}" } },
                active_border   = { colors = { "${
                  if theme == "dark" then scheme.base0F else scheme.base05
                }" } },
              },

              resize_on_border  = false,

              -- see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
              allow_tearing     = false,

              layout            = "scrolling",
            },

            decoration = {
              border_part_of_window = false,
              rounding              = 0,
              rounding_power        = 1,

              active_opacity        = 1,
              inactive_opacity      = 0.95,

              blur                  = {
                enabled  = true,
                xray     = true,
                size     = 8,
                passes   = 3,
                vibrancy = 0.1696,
              },

              shadow = {
                enabled      = false,
                range        = 15,
                render_power = 4,
                color        = "${scheme.base01}",
                offset       = { 5, 5 }
              },
            },

            animations = {
              enabled = true,
            },


            --         ▀
            -- █▀█▀▄  ▀█   ▄▀▀▀▀ ▄▀▀▀▄
            -- █ █ █   █    ▀▀▀▄ █
            -- █ █ █  ▄█▄  ▄▄▄▄▀ ▀▄▄▄▀

            misc = {
              force_default_wallpaper    = 0,
              disable_hyprland_logo      = true,
              animate_manual_resizes = false,
              animate_mouse_windowdragging = false,
              disable_splash_rendering = true,
              middle_click_paste         = false,
              enable_swallow             = true,
              on_focus_under_fullscreen  = 1,
              initial_workspace_tracking = true,
              disable_autoreload         = false,
              layers_hog_keyboard_focus  = false,
              focus_on_activate          = true,
              vrr = 0,
              session_lock_blur = true,
              session_lock_xray = true,
              render_unfocused_fps = 5,
            },

            binds = {
              hide_special_on_workspace_change = true,
            },

            render = {
              async_commit = true,
              direct_scanout = 1,
              new_render_scheduling = false,
              use_fp16 = 1,
              cm_enabled = false,
              cm_auto_hdr = 0,
              non_shader_cm = 3,
            },

            --  ▀                       █
            -- ▀█   █▀▀▀▄ █▀▀▀▄ █   █  ▀█▀
            --  █   █   █ █   █ █   █   █
            -- ▄█▄  █   █ █▄▄▄▀ ▀▄▄▄█   ▀▄▄
            --            █
            layout = {
              single_window_aspect_ratio = { 16, 9 },
            },

            input = {
              kb_layout           = "us",
              kb_variant          = "",
              kb_model            = "",
              kb_options          = "",
              kb_rules            = "",
              repeat_rate         = 40,
              repeat_delay        = 370,
              float_switch_override_focus = 0,

              focus_on_close      = 2,

              follow_mouse        = 2,
              mouse_refocus       = false,

              sensitivity         = 0, -- -1.0 - 1.0, 0 means no modification.

              virtualkeyboard     = {
                release_pressed_on_close = true,
              },
            },
            cursor = {
              no_warps = true,
              use_cpu_buffer = 2,
              no_hardware_cursors = 0,
            },
            ecosystem = {
              enforce_permissions = true,
              no_update_news = true,
              no_donation_nag = true,
            },

           -- ▀█                             █
           --  █    ▀▀▀▄ █   █ ▄▀▀▀▄ █   █  ▀█▀  ▄▀▀▀▀
           --  █   ▄▀▀▀█ █   █ █   █ █   █   █    ▀▀▀▄
           --  ▀▄▄ ▀▄▄▄█ ▀▄▄▄█ ▀▄▄▄▀ ▀▄▄▄█   ▀▄▄ ▄▄▄▄▀
           --             ▄▄▄▀
            scrolling = {
              direction = "right",
              fullscreen_on_one_column = false,
              wrap_swapcol = false,
              wrap_focus = false,
            },
          })
        '';
    };
}
