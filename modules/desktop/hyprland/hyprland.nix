{
  tack.inputs = {
    hyprland = {
      url = "gh:hyprwm/Hyprland";
      group = "hypr";
    };
  };
  exo.mods.desktop = {
    forte.hyprland = {
      enable = true;
      withUWSM = true;
      withTermFileChooser = true;
      withHyprpolkit = false;
      withHyprshutdown = true;
      withHypridle = false;
    };
  };

  exo.skeleton =
    {
      lib,
      config,
      pkgs,
      self',
      constants,
      ...
    }:
    let
      cfg = config.forte.hyprland;
    in
    {
      config =
        lib.mkIf cfg.enable
        <| lib.mkMerge [
          {
            hj.packages = [ cfg.package ];
            forte.persist.home.directories = [ ".config/hypr" ];
            hj.xdg.config.files = lib.mkMerge [
              {
                "hypr/hyprland.lua".text =
                  cfg.lua
                  |> lib.filterAttrs (_: file: file.autoLoad)
                  |> builtins.attrNames
                  |> lib.partition (name: name == "settings")
                  |> (part: part.right ++ part.wrong)
                  |> map (name: ''require("${name}")'')
                  |> (
                    rs:
                    rs
                    ++ [
                      #lua
                      ''
                        if io.open("${config.hj.xdg.config.directory}/hypr/dynamic.lua", "r") then
                          require("dynamic")
                        end
                      ''
                    ]
                  )
                  |> builtins.concatStringsSep "\n";
              }
              (
                cfg.lua
                |> lib.mapAttrs' (
                  name: file:
                  lib.nameValuePair "hypr/${name}.lua" {
                    source = pkgs.writeTextFile {
                      name = "${name}.lua";
                      text = file.content;
                      checkPhase = ''
                        if ! ${pkgs.lua}/bin/luac -p "$out"; then
                          echo -e "\nLua Error: ${name} has incorrect syntax\n"
                          exit 1
                        fi
                      '';
                    };
                  }
                )
              )
              {
                # Needed for lua stub file
                "hypr/.luarc.json".text = # json
                  ''
                    {
                      "workspace": {
                        "library": [
                          "${cfg.package}/share/hypr/stubs"
                        ]
                      }
                    }
                  '';
                "hypr/xdph.conf".text = # kdl
                  ''
                    screencopy {
                        max_fps = 60
                        allow_token_by_default = true
                    }
                  '';
              }
            ];
            services.graphical-desktop.enable = true;
            services.speechd.enable = lib.mkForce false;

            programs.xwayland.enable = true;

            systemd.user.settings.Manager.DefaultEnvironment =
              "PATH=/run/wrappers/bin:/etc/profiles/per-user/%u/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin:$PATH";

            xdg.portal = {
              wlr.enable = false;
              enable = true;
              extraPortals = [
                cfg.portalPackage
                pkgs.xdg-desktop-portal-gtk
              ];
              configPackages = lib.mkDefault [ cfg.package ];
            };
            security.pam.services.login.enableGnomeKeyring = true;
            services.getty.autologinUser = constants.username;

            # Auto start wayland session on tty1 if no session exists
            programs.bash.loginShellInit = # bash
              ''
                if [[ -z "$DISPLAY" && -z "$WAYLAND_DISPLAY" && "$(tty)" == '/dev/tty1' ]]; then
                  ${
                    if cfg.withUWSM then
                      "exec uwsm start hyprland-uwsm.desktop"
                    else
                      "exec ${lib.getExe' cfg.package "start-hyprland"}"
                  }
                fi
              '';
          }
          # auto load the plugins
          (lib.mkIf (cfg.plugins != [ ]) {
            forte.hyprland.lua.plugin-start = # lua
              ''
                hl.on("hyprland.start", function()
                ${
                  cfg.plugins
                  |> lib.concatMapStrings (entry: ''
                    hl.dispatch(hl.dsp.exec_raw("${cfg.package}/bin/hyprctl plugin load ${
                      if lib.types.package.check entry then "${entry}/lib/lib${entry.pname}.so" else entry
                    }"))
                  '')
                }
                end)
              '';
          })
          (lib.mkIf cfg.withTermFileChooser {
            xdg.portal.config.hyprland = {
              default = lib.mkForce [
                "hyprland"
                "gtk"
              ];
              "org.freedesktop.impl.portal.FileChooser" = lib.mkForce [ "termfilechooser" ];
              "org.freedesktop.impl.portal.Secret" = lib.mkForce [ "gnome-keyring" ];
              "org.freedesktop.impl.portal.Chooser" = lib.mkForce [ "none" ];
              "org.freedesktop.impl.portal.AppChooser" = lib.mkForce [ "none" ];
            };
          })
          (lib.mkIf (cfg.withUWSM) {
            forte.xdg.desktopEntries."uuctl".noDisplay = true;
            programs.uwsm.enable = true;
          })
          (lib.mkIf cfg.withHyprpolkit {
            hj.systemd.services.hyprpolkitagent = {
              description = "Hyprpolkitagent - Polkit authentication agent";
              wantedBy = [ "graphical-session.target" ];
              wants = [ "graphical-session.target" ];
              after = [ "graphical-session.target" ];
              serviceConfig = {
                Type = "simple";
                ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
                Restart = "on-failure";
                RestartSec = 1;
                TimeoutStopSec = 10;
              };
            };
          })
          (lib.mkIf cfg.withHyprshutdown {
            environment.shellAliases = {
              shutdown = ''${lib.getExe pkgs.hyprshutdown} -t "Shutting down..." --post-cmd "shutdown -P 0"'';
              reboot = ''${lib.getExe pkgs.hyprshutdown} -t "Restarting..." --post-cmd "reboot"'';
            };
          })
          (lib.mkIf (cfg.withHypridle) {
            hj.packages = [ pkgs.hypridle ];
            hj.systemd.services.hypridle = {
              description = "Hypridle autostart";
              after = [ "graphical-session.target" ];
              wantedBy = [ "graphical-session.target" ];
              serviceConfig = {
                Type = "simple";
                ExecStart = "${lib.getExe pkgs.hypridle}";
                Restart = "on-failure";
                RestartSec = 1;
                TimeoutStopSec = 10;
              };
            };
            hj.xdg.config.files = {
              "hypr/hypridle.conf".text = # bash
                ''
                  general {
                      ignore_dbus_inhibit = false
                      ignore_systemd_inhibit = false
                      #lock the computer before sleeping
                      before_sleep_cmd = ${config.forte.quickshell.package}/bin/tuishell ipc call lock lock
                  }
                  listener {
                      timeout = 500
                      on-timeout = ${config.forte.quickshell.package}/bin/tuishell ipc call lock lock
                  }
                  listener {
                      timeout = 600 # 600 seconds = 10 minutes
                      on-timeout = ${config.forte.hyprland.package}/bin/hyprctl dispatch 'hl.dsp.dpms({ action = "disable" })'  # Turn off the screen
                      on-resume = ${config.forte.hyprland.package}/bin/hyprctl dispatch 'hl.dsp.dpms({ action = "enable" })'  # Turn it on when waking up
                  }
                '';
            };
          })
        ];
      options.forte.hyprland = {
        enable = lib.mkEnableOption ''
          Hyprland, the dynamic tiling Wayland compositor that doesn't sacrifice on its looks.
          You can manually launch Hyprland by executing {command}`start-hyprland` on a TTY.
          A configuration file will be generated in {file}`~/.config/hypr/hyprland.conf`.
          See <https://wiki.hyprland.org> for more information'';

        package = lib.mkOption {
          type = lib.types.package;
          default = self'.packages.hyprland;
        };

        portalPackage = lib.mkOption {
          type = lib.types.package;
          default = self'.packages.xdg-desktop-portal-hyprland;
        };

        plugins = lib.mkOption {
          type = with lib.types; listOf (either package path);
          default = [ ];
          description = ''
            List of Hyprland plugins to use. Can either be packages or
            absolute plugin paths.
          '';
        };
        lua = lib.mkOption {
          type =
            with lib.types;
            attrsOf (
              coercedTo (either path lines)
                (content: {
                  inherit content;
                  autoLoad = true;
                })
                (submodule {
                  options = {
                    content = lib.mkOption {
                      type = either path lines;
                      description = ''
                        Lua file content, either as a multi-line string or a path to a .lua file.
                      '';
                    };
                    autoLoad = lib.mkOption {
                      type = bool;
                      default = true;
                      description = ''
                        Whether to generate a require() call for this file in hyprland.lua.
                        Set to false for helper modules imported by other Lua files.
                      '';
                    };
                  };
                })
            );
          default = { };
          description = ''
            Lua files written to $XDG_CONFIG_HOME/hypr.

            Attribute names become file names: dots become directory separators and
            .lua is appended if missing. For example, "lib.helpers" writes
            hypr/lib/helpers.lua and "settings" writes hypr/settings.lua.

            Files with autoLoad = true are require()'d in hyprland.lua in
            alphabetical order. Use numeric prefixes (e.g. "00-variables",
            "01-settings") to control load order.
          '';
        };

        withUWSM = lib.mkEnableOption "uwsm";
        withTermFileChooser = lib.mkEnableOption "termfilchooser";
        withHyprpolkit = lib.mkEnableOption "hyprpolkit";
        withHyprshutdown = lib.mkEnableOption "hyprshutdown";
        withHypridle = lib.mkEnableOption "hypridle";
      };
    };
  perSystem =
    {
      packages',
      pkgs,
      self',
      ...
    }:
    {
      packages = {
        hyprland = packages'.hyprland.overrideAttrs (oldAttrs: {
          doCheck = false;
          patches = (oldAttrs.patches or [ ]) ++ [
            (pkgs.writeText "per-workspace-scrolling-width" # cpp
              ''
                diff --git a/src/layout/algorithm/tiled/scrolling/ScrollingAlgorithm.cpp b/src/layout/algorithm/tiled/scrolling/ScrollingAlgorithm.cpp
                index c2dd3a4..a778aab 100644
                --- a/src/layout/algorithm/tiled/scrolling/ScrollingAlgorithm.cpp
                +++ b/src/layout/algorithm/tiled/scrolling/ScrollingAlgorithm.cpp
                @@ -582,6 +582,23 @@ bool SScrollingData::visible(SP<SColumnData> c, bool full) {
                     return false;
                 }

                +static std::vector<float> parseColumnWidths(const std::string& dir) {
                +    auto          widthVec = std::vector<float>();
                +
                +    char sep = dir.find(',') != std::string::npos ? ',' : ' ';
                +    CConstVarList widths(dir, 0, sep);
                +    for (auto& w : widths) {
                +        if (w.empty())
                +            continue;
                +        try {
                +            widthVec.emplace_back(std::clamp(std::stof(std::string{w}), MIN_COLUMN_WIDTH, MAX_COLUMN_WIDTH));
                +        } catch (...) { LOG(Log::ERR, "scrolling: Failed to parse width {} as float", w); }
                +    }
                +    if (widthVec.empty())
                +        widthVec = {0.333, 0.5, 0.667, 1.0}; // default
                +    return widthVec;
                +}
                +
                 CScrollingAlgorithm::CScrollingAlgorithm() : m_scrollingFullscreenHandler(makeUnique<Fullscreen::ScrollingFullscreenHandler::CScrollingFullscreenHandler>(this)) {
                     static const auto PCONFWIDTHS    = CConfigValue<Config::STRING>("scrolling:explicit_column_widths");
                     static const auto PCONFDIRECTION = CConfigValue<Config::STRING>("scrolling:direction");
                @@ -589,21 +606,6 @@ CScrollingAlgorithm::CScrollingAlgorithm() : m_scrollingFullscreenHandler(makeUn
                     m_scrollingData       = makeShared<SScrollingData>(this);
                     m_scrollingData->self = m_scrollingData;

                -    // Helper to parse explicit_column_widths string
                -    auto parseColumnWidths = [](const std::string& dir) -> std::vector<float> {
                -        auto          widthVec = std::vector<float>();
                -
                -        CConstVarList widths(dir, 0, ',');
                -        for (auto& w : widths) {
                -            try {
                -                widthVec.emplace_back(std::clamp(std::stof(std::string{w}), MIN_COLUMN_WIDTH, MAX_COLUMN_WIDTH));
                -            } catch (...) { LOG(Log::ERR, "scrolling: Failed to parse width {} as float", w); }
                -        }
                -        if (widthVec.empty())
                -            widthVec = {0.333, 0.5, 0.667, 1.0}; // default
                -        return widthVec;
                -    };
                -
                     // Helper to parse direction string
                     auto parseDirection = [](const std::string& dir) -> eScrollDirection {
                         if (dir == "left")
                @@ -616,7 +618,7 @@ CScrollingAlgorithm::CScrollingAlgorithm() : m_scrollingFullscreenHandler(makeUn
                             return SCROLL_DIR_RIGHT; // default
                     };

                -    m_configCallback = Event::bus()->m_events.config.reloaded.listen([this, parseColumnWidths, parseDirection] {
                +    m_configCallback = Event::bus()->m_events.config.reloaded.listen([this, parseDirection] {
                         static const auto PCONFDIRECTION = CConfigValue<Config::STRING>("scrolling:direction");

                         m_config.configuredWidths.clear();
                @@ -1259,14 +1261,15 @@ Config::ErrorResult CScrollingAlgorithm::layoutMsg(const std::string_view& sv) {
                             if (ARGS[1] == "+conf") {
                                 auto col = TDATA->column.lock();
                                 if (col) {
                -                    for (size_t i = 0; i < m_config.configuredWidths.size(); ++i) {
                -                        if (m_config.configuredWidths[i] > col->getColumnWidth()) {
                -                            col->setColumnWidth(m_config.configuredWidths[i]);
                +                    auto dynamicWidths = getDynamicWidths();
                +                    for (size_t i = 0; i < dynamicWidths.size(); ++i) {
                +                        if (dynamicWidths[i] > col->getColumnWidth()) {
                +                            col->setColumnWidth(dynamicWidths[i]);
                                             break;
                                         }

                -                        if (i == m_config.configuredWidths.size() - 1)
                -                            col->setColumnWidth(m_config.configuredWidths[0]);
                +                        if (i == dynamicWidths.size() - 1)
                +                            col->setColumnWidth(dynamicWidths[0]);
                                     }
                                 }

                @@ -1274,14 +1277,15 @@ Config::ErrorResult CScrollingAlgorithm::layoutMsg(const std::string_view& sv) {
                             } else if (ARGS[1] == "-conf") {
                                 auto col = TDATA->column.lock();
                                 if (col) {
                -                    for (size_t i = m_config.configuredWidths.size() - 1;; --i) {
                -                        if (m_config.configuredWidths[i] < col->getColumnWidth()) {
                -                            col->setColumnWidth(m_config.configuredWidths[i]);
                +                    auto dynamicWidths = getDynamicWidths();
                +                    for (size_t i = dynamicWidths.size() - 1;; --i) {
                +                        if (dynamicWidths[i] < col->getColumnWidth()) {
                +                            col->setColumnWidth(dynamicWidths[i]);
                                             break;
                                         }

                                         if (i == 0) {
                -                            col->setColumnWidth(m_config.configuredWidths.back());
                +                            col->setColumnWidth(dynamicWidths.back());
                                             break;
                                         }
                                     }
                @@ -1966,6 +1970,15 @@ eScrollDirection CScrollingAlgorithm::getDynamicDirection() {
                         return SCROLL_DIR_RIGHT; // default
                 }

                +std::vector<float> CScrollingAlgorithm::getDynamicWidths() {
                +    const auto WORKSPACERULE = Config::workspaceRuleMgr()->getWorkspaceRuleFor(m_parent->space()->workspace());
                +    if (WORKSPACERULE && WORKSPACERULE->m_layoutopts.contains("explicit_column_widths")) {
                +        return parseColumnWidths(WORKSPACERULE->m_layoutopts.at("explicit_column_widths"));
                +    }
                +
                +    return m_config.configuredWidths;
                +}
                +
                 CBox CScrollingAlgorithm::usableArea() const {
                     if (!m_parent || !m_parent->space())
                         return {};
                diff --git a/src/layout/algorithm/tiled/scrolling/ScrollingAlgorithm.hpp b/src/layout/algorithm/tiled/scrolling/ScrollingAlgorithm.hpp
                index 98a43be..4f1d31b 100644
                --- a/src/layout/algorithm/tiled/scrolling/ScrollingAlgorithm.hpp
                +++ b/src/layout/algorithm/tiled/scrolling/ScrollingAlgorithm.hpp
                @@ -148,6 +148,7 @@ namespace Layout::Tiled {
                         } m_config;

                         eScrollDirection         getDynamicDirection();
                +        std::vector<float>       getDynamicWidths();

                         SP<SScrollingTargetData> findBestNeighbor(SP<SScrollingTargetData> pCurrent, SP<SColumnData> pTargetCol);
                         SP<SScrollingTargetData> closestNode(const Vector2D& posGlobglobgabgalab);

              ''
            )
          ];
        });
        xdg-desktop-portal-hyprland = packages'.hyprland.xdg-desktop-portal-hyprland.overrideAttrs {
          doCheck = false;
        };
      };
      remotePackages = {
        hyprland-bundle = pkgs.symlinkJoin {
          name = "hyprland-bundle";
          paths = [
            self'.packages.hyprland
            self'.packages.xdg-desktop-portal-hyprland
            self'.legacyPackages.scrolloverview
            self'.legacyPackages.borders-plus-plus
          ];
        };
      };
    };
}
