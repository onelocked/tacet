{
  exo.mods.desktop =
    {
      config,
      scheme,
      ...
    }:
    let
      gtk = config.forte.gtk;
    in
    {
      forte.qt = {
        enable = true;
        settings = {
          Appearance = {
            icon_theme = gtk.icons.name;
            standard_dialogs = "default";
            style = "Adwaita-Dark";
          };
        };
        font = {
          name = gtk.font.serif;
          size = gtk.font.size;
        };
        palette = with scheme; [
          base07
          base00
          "#ffffff"
          "#cacaca"
          "#9f9f9f"
          "#b8b8b8"
          base07
          "#ffffff"
          base07
          base00
          base00
          "#000000"
          base0D
          base06
          base05
          base0F
          base03
          base00
          base03
          base07
          base07
          base0F
        ];
      };
    };

  exo.skeleton =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.forte.qt;
      ini = (pkgs.formats.ini { }).generate;
    in
    {
      config = lib.mkIf cfg.enable {
        qt = {
          enable = true;
          style = "adwaita-dark";
        };

        environment.sessionVariables = {
          QT_QPA_PLATFORMTHEME = "xdgdesktopportal";
          QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
        };

        hj.xdg.config.files =
          [
            "qt5ct/qt5ct.conf"
            "qt6ct/qt6ct.conf"
          ]
          |> map (f: lib.nameValuePair f { source = ini "qtct.conf" cfg.settings; })
          |> builtins.listToAttrs;

        forte.xdg.desktopEntries =
          [
            "qt5ct"
            "qt6ct"
          ]
          |> map (f: lib.nameValuePair f { noDisplay = true; })
          |> builtins.listToAttrs;
      };

      options.forte.qt = {
        enable = lib.mkEnableOption "Qt";

        settings = lib.mkOption {
          type = lib.types.attrs;
          default = { };
          apply =
            userSettings:
            let
              fName = cfg.font.name;
              fSize = cfg.font.size;
              qtFontString = ''"${fName},${fSize},-1,5,400,0,0,0,0,0,0,0,0,0,0,1"'';
            in
            (lib.recursiveUpdate {
              Appearance = {
                color_scheme_path = cfg.palette;
                custom_palette = true;
              };
            } userSettings)
            // {
              Fonts = (userSettings.Fonts or { }) // {
                fixed = qtFontString;
                general = qtFontString;
              };
            };
        };
        font = {
          name = lib.mkOption {
            type = lib.types.str;
            default = config.forte.gtk.font.serif;
          };
          size = lib.mkOption {
            type = lib.types.str;
            default = "12";
          };
        };

        palette = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          description = "List of 22 color hex codes for the Qt palette.";
          default = [ ];
          apply =
            colors:
            ini "colors.conf" {
              ColorScheme = lib.genAttrs [ "active_colors" "disabled_colors" "inactive_colors" ] (
                _: lib.concatStringsSep ", " colors
              );
            };
        };
      };
    };
}
