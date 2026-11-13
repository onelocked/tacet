{
  exo.mods.desktop = {
    forte.foot = {
      settings = {
        main = {
          font = "Maple Mono NL NF:style=ExtraBold:size=12";
          font-bold = "SFMono Nerd Font:style=Heavy:size=12";
          font-italic = "SF Mono:style=Bold Italic:size=12";
          font-bold-italic = "SF Mono:style=Heavy Italic:size=12";

          pad = "8x3x8x0";
          dpi-aware = "yes";
          bold-text-in-bright = "no";
          gamma-correct-blending = "no";
        };

        scrollback = {
          lines = 10000;
        };

        cursor = {
          style = "block";
          unfocused-style = "hollow";
          blink = "yes";
          blink-rate = 500;
          underline-thickness = 3;
        };

        mouse = {
          hide-when-typing = "yes";
        };

        mouse-bindings = {
          select-extend = "none";
          clipboard-copy = "BTN_RIGHT";
        };

        tweak = {
          render-timer = "none";
          overflowing-glyphs = "yes";
          font-monospace-warn = "no";
          surface-bit-depth = "8-bit";
        };
        colors-dark = {
          background = "131316";
          foreground = "e5e1e6";
          selection-background = "c5c0ff";
          selection-foreground = "131316";
          regular0 = "131316"; # color0
          regular1 = "ffb4ab"; # color1
          regular2 = "a6e3a1"; # color2
          regular3 = "d4b483"; # color3
          regular4 = "c5c0ff"; # color4
          regular5 = "e4a8d4"; # color5
          regular6 = "6fbac2"; # color6
          regular7 = "c8c5d0"; # color7
          bright0 = "6f6d78"; # color8
          bright1 = "ffcbc2"; # color9
          bright2 = "c1ecbd"; # color10
          bright3 = "e5cfa8"; # color11
          bright4 = "dcd8ff"; # color12
          bright5 = "f0c4e4"; # color13
          bright6 = "b5e5e9"; # color14
          bright7 = "e5e1e6"; # color15
        };
      };
    };
  };
  exo.skeleton =
    {
      lib,
      pkgs,
      wrapPackage,
      config,
      ...
    }:
    let
      cfg = config.forte.foot;
    in
    {
      config = lib.mkIf (cfg.enable) {
        forte.xdg.desktopEntries = {
          "footclient".noDisplay = true;
          "foot-server".noDisplay = true;
        };
        xdg.mime.defaultApplications =
          [
            "terminal"
            "x-terminal-emulator"
            "inode/directory"
          ]
          |> map (mime: lib.nameValuePair mime [ "foot.desktop" ])
          |> lib.listToAttrs;
        hj = {
          packages = [ cfg.package ];
          systemd.services.foot-server = {
            description = "Fast, lightweight and minimalistic Wayland terminal emulator.";
            after = [ "graphical-session.target" ];
            wantedBy = [ "graphical-session.target" ];
            serviceConfig = {
              ExecStart = "${cfg.package}/bin/foot --server";
              Restart = "on-failure";
              OOMPolicy = "continue";
            };
          };
        };
      };
      options.forte.foot = {
        enable = lib.mkEnableOption "foot";
        settings = lib.mkOption {
          type = lib.types.attrs;
          default = { };
          description = "Settings for foot";
        };
        package = lib.mkOption {
          type = lib.types.package;
          default = wrapPackage {
            package = pkgs.foot;
            files.configuration."foot.ini" = wrapPackage.ini cfg.settings;
            args = [
              "--config"
              "${wrapPackage.out}/configuration/foot.ini"
            ];
            env = {
              FONTCONFIG_FILE = pkgs.makeFontsConf { fontDirectories = [ pkgs.maple-mono.NL-NF ]; };
            };
          };
          defaultText = lib.literalExpression "pkgs.foot";
          description = "Package to use for foot";
        };
      };
    };
}
