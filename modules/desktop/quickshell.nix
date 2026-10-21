{ inputs, ... }:
{
  tack.inputs = {
    tuishell = {
      url = "git+https://gitea.onelock.org/onelock/tuishell";
      type = "fetch";
      group = "desktop";
    };
    quickshell = {
      url = "gh:quickshell-mirror/quickshell";
      group = "desktop";
    };
  };
  exo.mods.desktop =
    {
      lib,
      pkgs,
      wrapPackage,
      self',
      config,
      constants,
      theme,
      ...
    }:
    let
      cfg = config.forte.quickshell;
    in
    {
      config = lib.mkIf (cfg.enable) {
        hj = {
          packages = [ cfg.package ];
          systemd.services.tuishell = {
            enableDefaultPath = false;
            description = "tuishell";
            after = [ "graphical-session.target" ];
            wantedBy = [ "graphical-session.target" ];
            serviceConfig = {
              Type = "simple";
              ExecStart = "${cfg.package}/bin/tuishell";
              Restart = "on-failure";

              MemoryHigh = "512M";
              MemoryMax = "768M";
            };
          };
          systemd.services.awww = {
            description = "awww wallpaper daemon";
            wantedBy = [ "graphical-session.target" ];
            partOf = [ "graphical-session.target" ];
            after = [ "graphical-session.target" ];
            serviceConfig = {
              Type = "simple";
              ExecStart = "${lib.getExe' pkgs.awww "awww-daemon"}";
              Restart = "on-failure";
              RestartSec = 1;
              TimeoutStopSec = 10;

              # --- Hardening ---
              ProtectSystem = "strict";
              ProtectHome = "read-only";

              ReadWritePaths = [ "%t" ];
              PrivateTmp = true;

              InaccessiblePaths = [
                "-%h/.ssh"
                "-%h/.gnupg"
                "-%h/.config/sops"
                "-/persist/home"
              ];

              NoNewPrivileges = true;
              CapabilityBoundingSet = "";

              ProtectKernelTunables = true;
              ProtectKernelModules = true;
              ProtectKernelLogs = true;
              ProtectControlGroups = true;
              ProtectClock = true;
              ProtectHostname = true;
              ProtectProc = "invisible";

              RestrictAddressFamilies = [ "AF_UNIX" ];

              SystemCallArchitectures = "native";
              SystemCallFilter = [
                "~@mount"
                "~@module"
                "~@raw-io"
                "~@reboot"
                "~@swap"
                "~@obsolete"
                "~@privileged"
                "~@setuid"
              ];
            };
          };
        };
        forte.hyprland.lua.settings = # lua
          ''
            hl.layer_rule({
              name = "tuishell",
              match = {
                namespace = "^tuishell-.*",
              },
              no_anim = true,
              ignore_alpha = 0.1,
              blur = false,
              blur_popups = false,
              xray = true,
            })
          '';
        forte.hyprland.lua.keybinds =
          {
            "ALT + SHIFT + equal" = "brightness increase";
            "ALT + SHIFT + minus" = "brightness decrease";
            "ALT + SHIFT + W" = "desktop toggleWidgets";
            "SUPER + SPACE" = "launcher toggle";
            "SUPER + ALT + L" = "lock lock";
            "SUPER + SHIFT + Z" = "emoji toggle";
            "ALT + SHIFT + A " = "booru toggle";
          }
          |> lib.mapAttrsToList (
            key: cmd: # lua
            ''
              hl.bind("${key}", hl.dsp.exec_raw("tuishell ipc call ${cmd}"), { repeating = false })
            ''
          )
          |> lib.join "\n";
        systemd.tmpfiles.settings.preservation = {
          "${config.hj.directory}/.netrc".z = lib.mkForce {
            user = constants.username;
            group = "users";
            mode = "0600";
          };
        };
        forte.persist.home = {
          files = [ ".netrc" ];
          directories = [ ".cache/tuishell" ];
        };
      };
      options = {
        forte.quickshell = {
          enable = lib.mkEnableOption "quickshell" // {
            default = true;
          };
          package = lib.mkOption {
            type = lib.types.package;
            default = wrapPackage {
              binName = "tuishell";
              args = [ "-p ${inputs.tuishell}" ];
              package =
                let
                  extraPkgs =
                    with pkgs.kdePackages;
                    [ qtmultimedia ]
                    ++ (with pkgs; [
                      ddcutil
                      imagemagick
                      cava
                      python3
                      awww
                      app2unit
                      libnotify
                      config.forte.mpv.mpv-wlpaste
                    ]);

                  qmlImportPath = lib.makeSearchPath pkgs.kdePackages.qtbase.qtQmlPrefix extraPkgs; # lib/qt-6/qml
                  qtPluginPath = lib.makeSearchPath pkgs.kdePackages.qtbase.qtPluginPrefix extraPkgs; # lib/qt-6/plugins
                in
                wrapPackage {
                  inherit extraPkgs;
                  package = self'.packages.quickshell;
                  aliases = [ "qs" ];
                  env = {
                    QT_QPA_PLATFORMTHEME = "xdgdesktopportal";
                    QS_ICON_THEME = config.forte.gtk.icons.name;
                    QS_DROP_EXPENSIVE_FONTS = "1";
                    QML_IMPORT_PATH = qmlImportPath;
                    QML2_IMPORT_PATH = qmlImportPath;
                    QT_PLUGIN_PATH = qtPluginPath;
                    FONTCONFIG_FILE = pkgs.makeFontsConf { fontDirectories = [ pkgs.lucide ]; };
                    TUISHELL_THEME = theme;
                  };
                };
            };
          };
        };
      };
    };
  perSystem =
    { packages', ... }:
    {
      remotePackages.quickshell =
        (packages'.quickshell.override {
          withWayland = true;
          withPipewire = true;
          withQtSvg = true;
          withJemalloc = true;
          withHyprland = true;
          withNetworkManager = true;
          withPolkit = true;
          withPam = true;

          withX11 = false;
          withI3 = false;
        }).overrideAttrs
          { doCheck = false; };
    };
}
