{
  exo.mods.media =
    { config, scheme, ... }:
    {
      forte.mpv = {
        enable = true;
        conf = # ini
          ''
            osd-duration=500
            osc=no
            video-sync=display-resample
            interpolation=yes
            volume=80
            ao=pipewire
            audio-buffer=0.1
            audio-file-auto=fuzzy
            sub-auto=fuzzy
            sub-font="Apple Color Emoji"
            gpu-context=auto
            hwdec=auto-safe
            profile=gpu-hq
            vo=gpu-next
            gpu-api=auto
            deband=yes
            wayland-edge-pixels-pointer=0
            wayland-edge-pixels-touch=0
            screenshot-format=webp
            screenshot-webp-lossless=yes
            screenshot-directory=${config.hj.directory}/Pictures/Screenshots/mpv
            screenshot-sw=yes
            input-default-bindings=yes
            ytdl-format=bestvideo[height<=2160]+bestaudio/best[height<=2160]
            loop-file=inf
            autofit=x1355
            msg-level=ffmpeg=fatal,vd=fatal,vo=fatal
            background=color
            background-color="${scheme.base00}"
          '';
        input = # bash
          ''
            MBTN_LEFT cycle pause
            WHEEL_DOWN add volume -1
            WHEEL_UP add volume 1
            S screenshot video

            h no-osd seek -5 exact
            LEFT no-osd seek -5 exact
            l no-osd seek 5 exact
            RIGHT no-osd seek 5 exact
            j seek -30
            DOWN seek -30
            k seek 30
            UP seek 30

            H no-osd seek -1 exact
            Shift+LEFT no-osd seek -1 exact
            L no-osd seek 1 exact
            Shift+RIGHT no-osd seek 1 exact
            J seek -300
            Shift+DOWN seek -300
            K seek 300
            Shift+UP seek 300

            Ctrl+LEFT no-osd sub-seek -1
            Ctrl+h no-osd sub-seek -1
            Ctrl+RIGHT no-osd sub-seek 1
            Ctrl+l no-osd sub-seek 1
            Ctrl+DOWN add chapter -1
            Ctrl+j add chapter -1
            Ctrl+UP add chapter 1
            Ctrl+k add chapter 1

            Alt+LEFT frame-back-step
            Alt+h frame-back-step
            Alt+RIGHT frame-step
            Alt+l frame-step

            PGUP add chapter 1
            PGDWN add chapter -1

            u revert-seek

            Ctrl++ add sub-scale 0.1
            Ctrl+- add sub-scale -0.1
            Ctrl+0 set sub-scale 0

            q quit
            p cycle pause
            SPACE cycle pause
            f cycle fullscreen

            n playlist-next
            N playlist-prev

            o show-progress

            s cycle sub
            v cycle video
            a cycle audio
            c add panscan 0.1
            PLAY cycle pause
            PAUSE cycle pause
            PLAYPAUSE cycle pause
            PLAYONLY set pause no
            PAUSEONLY set pause yes
            STOP stop
          '';
      };
    };
  exo.skeleton =
    {
      lib,
      pkgs,
      config,
      self',
      wrapPackage,
      ...
    }:
    let
      cfg = config.forte.mpv;
    in
    {
      config = lib.mkIf cfg.enable {
        hj.packages = [ cfg.package ];
        forte.hyprland.lua.window-rules = # lua
          ''
            hl.window_rule({
              name         = "mpv",
              match        = { class = "mpv" },
              center       = true,
              float        = true,
              opacity      = "1 override",
            })
          '';
        forte.xdg.desktopEntries."umpv".noDisplay = true;
        xdg.mime.defaultApplications =
          [
            # Audio
            "audio/aac"
            "audio/mpeg"
            "audio/ogg"
            "audio/opus"
            "audio/wav"
            "audio/webm"
            "audio/x-matroska"

            # Video
            "video/mp2t"
            "video/mp4"
            "video/mpeg"
            "video/ogg"
            "video/webm"
            "video/x-flv"
            "video/x-matroska"
            "video/x-msvideo"
          ]
          |> map (mime: lib.nameValuePair mime [ "mpv.desktop" ])
          |> lib.listToAttrs;
      };

      options.forte.mpv = {
        enable = lib.mkEnableOption "mpv";
        conf = lib.mkOption {
          default = "";
          type = lib.types.lines;
        };

        input = lib.mkOption {
          type = lib.types.lines;
          default = "";
        };
        package = lib.mkOption {
          type = lib.types.package;
          default = wrapPackage {
            package = pkgs.mpv;
            env.MPV_HOME = wrapPackage.out + "configuration";
            files.configuration = {
              "mpv.conf" = cfg.conf;
              "input.conf" = cfg.input;
              "scripts" = with pkgs.mpvScripts; [
                "${mpris}/share/mpv/scripts"
                "${sponsorblock}/share/mpv/scripts"
                "${modernz}/share/mpv/scripts"
                "${self'.legacyPackages.mpv-rotate-resize}/share/mpv/scripts"
              ];
              "fonts" = "${pkgs.mpvScripts.modernz}/share/fonts/truetype";
              "script-opts/rotate-resize.conf" = "keybinds=r";
              "script-opts/modernz.conf" = lib.generators.toKeyValue { } {
                download_path = config.hj.directory + "/Videos/mpv";
                osc_on_start = "no";
                osc_on_seek = "no";
                showonpause = "no";
              };
            };
          };
        };
        mpv-wlpaste = lib.mkOption {
          type = lib.types.package;
          default = pkgs.writeShellApplication {
            name = "mpv-wlpaste";
            runtimeInputs = with pkgs; [
              cfg.package
              wl-clipboard
              coreutils
            ];
            text = ''
              url=$(wl-paste | tr -d '[:space:]')
              if [ -z "$url" ]; then
                exit 0
              fi
              case "$url" in
                *tiktok.com*)
                  url="''${url%%\?*}"
                  ;;
              esac
              exec mpv "$url"
            '';
          };
        };
      };
    };
  perSystem =
    { pkgs, ... }:
    {
      legacyPackages.mpv-rotate-resize = pkgs.writeTextFile {
        name = "rotate-resize";
        destination = "/share/mpv/scripts/rotate-resize.lua";
        text = # lua
          ''
            local opt = require 'mp.options'
            local script_opts = { keybinds = "r" }
            opt.read_options(script_opts, "rotate-resize")
            mp.msg.info("rotate-resize loaded")

            local max_height = 1355
            local rotations = {0, 270, 180, 90}
            local cached = {}   -- keyed by rotation value -> { w, h }
            local rot_idx = 1   -- current index into rotations

            local function precalculate(w, h)
              cached = {}
              for _, rot in ipairs(rotations) do
                local tw = (rot == 90 or rot == 270) and h or w
                local th = (rot == 90 or rot == 270) and w or h
                local scale = max_height / th
                cached[rot] = { w = math.floor(tw * scale), h = math.floor(th * scale) }
              end
              mp.msg.info(string.format("rotate-resize: cached sizes for %dx%d", w, h))
            end

            -- fires when video params become available (before file-loaded)
            mp.register_event("video-reconfig", function()
              local w = mp.get_property_number("video-params/w")
              local h = mp.get_property_number("video-params/h")
              if w and h then precalculate(w, h) end
            end)

            -- mpv resets video-rotate on each new file, so mirror that here
            mp.register_event("file-loaded", function()
              rot_idx = 1
            end)

            mp.add_key_binding(script_opts.keybinds, "rotate-resize", function()
              if not next(cached) then
                mp.msg.warn("rotate-resize: dimensions not yet available")
                return
              end

              rot_idx = (rot_idx % #rotations) + 1
              local next_val = rotations[rot_idx]

              mp.set_property("video-rotate", next_val)

              local sz = cached[next_val]
              local cmd = string.format(
                [[hyprctl --batch "dispatch hl.dsp.window.resize({ x = %d, y = %d }) ; dispatch hl.dsp.window.center()"]],
                sz.w, sz.h
              )
              mp.command_native_async({
                name = "subprocess",
                args = {"sh", "-c", cmd}
              }, function() end)
            end)
          '';
      };
    };
}
