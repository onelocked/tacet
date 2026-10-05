{
  exo.mods.gaming =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      hardware.steam-hardware.enable = true;
      programs.steam = {
        enable = true;
        extraPackages = with pkgs; [
          mangohud
          gamemode
          pulseaudio
          systemd
        ];
        package = pkgs.steam.override {
          extraLibraries = pkgs: [
            pkgs.mangohud
            pkgs.gamemode.lib
          ];
          extraEnv = {
            DBUS_FATAL_WARNINGS = "0";
            GAMEMODERUNEXEC = "mangohud";

            PROTON_ENABLE_WAYLAND = 1;
            DXVK_ASYNC = "1";
            # Allow GPU render queueing
            DXGI_MAX_FRAME_LATENCY = "1";
            D3D9_MAX_FRAME_LATENCY = "1";
            MESA_SHADER_CACHE_MAX_SIZE = "10G";
          };
          extraPreBwrapCmds = # bash
            ''
              # Prevent buildFHSEnv from automatically bind-mounting all root host directories (like /home, /root, /var, etc.)
              ignored+=(/*)
            '';
          extraBwrapArgs = [
            "--ro-bind-try /sys /sys"
            "--ro-bind-try /run/udev /run/udev"
            "--ro-bind-try /run/opengl-driver /run/opengl-driver"
            "--ro-bind-try /run/opengl-driver-32 /run/opengl-driver-32"
            "--ro-bind-try /run/current-system /run/current-system"
            "--ro-bind-try /run/dbus /run/dbus"
            "--ro-bind-try /run/nscd /run/nscd"
            "--ro-bind-try /run/systemd /run/systemd"

            "--bind-try /tmp/.X11-unix /tmp/.X11-unix"
            "--bind-try $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY"
            "--bind-try $XDG_RUNTIME_DIR/wayland-0 $XDG_RUNTIME_DIR/wayland-0"
            "--bind-try $XDG_RUNTIME_DIR/pipewire-0 $XDG_RUNTIME_DIR/pipewire-0"
            "--bind-try $XDG_RUNTIME_DIR/pulse $XDG_RUNTIME_DIR/pulse"
            "--bind-try $XDG_RUNTIME_DIR/bus $XDG_RUNTIME_DIR/bus"
            "--ro-bind-try $XDG_RUNTIME_DIR/speech-dispatcher $XDG_RUNTIME_DIR/speech-dispatcher"
            "--bind-try $XDG_RUNTIME_DIR/gamemode $XDG_RUNTIME_DIR/gamemode"

            "--tmpfs $HOME"
            "--bind-try $HOME/.steam $HOME/.steam"
            "--bind-try $HOME/.local/share/Steam $HOME/.local/share/Steam"
            "--bind-try $HOME/.local/share/vulkan $HOME/.local/share/vulkan"
            "--bind-try $HOME/.cache/winetricks $HOME/.cache/winetricks"
            "--bind-try $HOME/.cache/umu-protonfixes $HOME/.cache/umu-protonfixes"
            "--bind-try $HOME/.cache/mesa_shader_cache $HOME/.cache/mesa_shader_cache"
            "--bind-try $HOME/.cache/mesa_shader_cache_db $HOME/.cache/mesa_shader_cache_db"
            "--bind-try $HOME/.cache/nvidia $HOME/.cache/nvidia"
            "--bind-try $HOME/.nv $HOME/.nv"
            "--bind-try $HOME/.config/shadPS4 $HOME/.config/shadPS4"
            "--bind-try $HOME/.local/share/shadPS4 $HOME/.local/share/shadPS4"
            "--ro-bind-try $HOME/.config/MangoHud $HOME/.config/MangoHud"
            "--ro-bind-try $HOME/.config/fontconfig $HOME/.config/fontconfig"
            "--ro-bind-try $HOME/.icons $HOME/.icons"
            "--ro-bind-try $HOME/.local/share/icons $HOME/.local/share/icons"
            "--ro-bind-try $HOME/.local/share/fonts $HOME/.local/share/fonts"
            "--bind-try $HOME/.local/share/applications $HOME/.local/share/applications"

            "--bind-try /games /games"
            "--bind-try /steam /steam"

            "--unshare-uts"
            "--unshare-ipc"
          ];
        };
      };

      forte.hyprland.lua.window-rules = # lua
        ''
          hl.on("workspace.active", function(ws)
            if not ws or ws.id ~= 5 then
              return
            end

            local steamExists   = false
            local friendsExists = false

            for _, win in ipairs(ws:get_windows()) do
              if win.class == "steam" then
                steamExists = true
                if win.title == "Friends List" then
                  friendsExists = true
                end
              end
            end

            if steamExists and not friendsExists then
              hl.exec_cmd("xdg-open steam://open/friends")
            end
          end)

          hl.window_rule({
            name = "steam-move-workspace",
            match = { class = "^steam$" },
            workspace = "5",
            scrolling_width = 0.505,
          })

          hl.window_rule({
            name = "float-steam-sub-windows",
            match = {
              title = "negative:Steam",
              class = "^steam$",
            },
            float = true,
          })

          hl.window_rule({
            name = "hide-steam-windows",
            match = {
              title = "^Steam Settings$",
              class = "^steam$",
            },
            border_color = "rgb(fede22)",
            border_size = 3,

            float = true,
            no_screen_share = true,
          })

          hl.window_rule({
            name = "steam-friends-list",
            match = {
              class = "^steam$",
              title = "^Friends List$",
            },
            float = false,
            scrolling_width = 0.1,
          })

          hl.window_rule({
            name = "steam-big-picture",
            match = {
              title = "Steam Big Picture Mode",
              class = "^steam$",
            },
            fullscreen_state = "3 3",
          })

          hl.window_rule({
            name = "move-all-games",
            match = {
              xdg_tag = "proton-game"
            },
            decorate = false,
            content = "game",
            workspace = "6",
            fullscreen_state = "3 3",
            idle_inhibit = "focus",
          })

          -- return to workspace media once the game is closed
          hl.on("window.close", function()
            local ws = hl.get_active_workspace()
            if ws ~= nil and ws.name == "6" then
              local windows = hl.get_workspace_windows(ws.name)
              if windows ~= nil and #windows <= 1 then
                hl.dispatch(hl.dsp.focus({ workspace = "5" }))
              end
            end
          end)
        '';

      hj.systemd.services = {
        steam-autostart = {
          enableDefaultPath = false;
          description = "steam autostart";
          after = [ "graphical-session.target" ];
          wantedBy = [ "graphical-session.target" ];
          serviceConfig = {
            Type = "simple";
            ExecStart = "${lib.getExe config.programs.steam.package}";
          };
        };
      };
    };
}
