{
  exo.mods.desktop =
    {
      lib,
      pkgs,
      config,
      self',
      ...
    }:
    let
      cfg = config.forte.gtk;
      cursor = config.forte.cursor;

      dconfSettings =
        with cfg;
        let
          mkFont = name: "${name} ${font.size}";
        in
        {
          "ca/desrt/dconf-editor".show-warning = false;
          "org/gnome/desktop/thumbnailers".disable-all = true;
          "org/gnome/desktop/screen-time-limits" = {
            history-enabled = false;
          };
          "org/gnome/desktop/media-handling" = {
            automount = false;
            automount-open = false;
            autorun-never = true;
          };
          "org/gnome/desktop/interface" = {
            gtk-theme = theme.name;
            icon-theme = icons.name;
            cursor-theme = cursor.name;
            cursor-size = cursor.size;
            color-scheme = "prefer-dark";
            font-name = mkFont font.sansSerif;
            document-font-name = mkFont font.serif;
            monospace-font-name = mkFont font.mono;
            font-antialiasing = "rgba";
            font-hinting = "full";
            text-scaling-factor = 1.0;
            gtk-enable-primary-paste = false;
            overlay-scrolling = false;
          };
        };
      managedKeysJson =
        dconfSettings
        |> lib.mapAttrsToList (dir: lib.mapAttrsToList (key: _: "/${dir}/${key}"))
        |> lib.concatLists
        |> builtins.toJSON
        |> pkgs.writeText "dconf-keys.json";
    in
    {
      config = lib.mkIf cfg.enable {
        hj.packages = with cfg; [
          theme.package
          icons.package
        ];

        hj.xdg.config.files = lib.optionalAttrs (cfg.theme.css != "") (
          [
            "4.0"
            "3.0"
          ]
          |> map (version: lib.nameValuePair "gtk-${version}/gtk.css" { text = cfg.theme.css; })
          |> builtins.listToAttrs
        );

        programs.dconf = {
          enable = true;
          profiles.user.databases = [
            {
              settings = dconfSettings;
              lockAll = true;
            }
          ];
        };

        hj.systemd.services.forte-dconf-cleanup = {
          description = "Cleanup unmanaged dconf keys";
          wantedBy = [ "graphical-session.target" ];
          partOf = [ "graphical-session.target" ];
          serviceConfig.Type = "oneshot";
          script = # bash
            ''
              STATE_DIR="${config.hj.xdg.state.directory}/hjem-dconf"
              mkdir -p "$STATE_DIR"

              OLD_STATE="$STATE_DIR/keys.json"
              NEW_STATE="${managedKeysJson}"

              if [[ -f "$OLD_STATE" ]]; then
                ${lib.getExe pkgs.jq} -r -n \
                  --slurpfile old "$OLD_STATE" \
                  --slurpfile new "$NEW_STATE" \
                  '($old[] - $new[])[]' | while read -r key; do
                    echo "Resetting unmanaged dconf key: $key"
                    ${lib.getExe pkgs.dconf} reset "$key"
                done
              fi

              cp "$NEW_STATE" "$OLD_STATE"
            '';
        };
      };

      options.forte.gtk = {
        enable = lib.mkEnableOption { } // {
          default = true;
        };

        theme = {
          name = lib.mkOption {
            description = "GTK Theme";
            type = lib.types.str;
            default = "adw-gtk3-light";
          };

          css = lib.mkOption {
            type = with lib.types; nullOr lines;
            default = "";
            description = "Raw css content";
          };

          package = lib.mkOption {
            description = "GTK Theme package";
            type = lib.types.nullOr lib.types.package;
            default = pkgs.adw-gtk3;
          };
        };

        icons = {
          name = lib.mkOption {
            description = "GTK Icon theme";
            type = lib.types.str;
            default = "Papirus-Light";
          };

          package = lib.mkOption {
            description = "GTK Icon theme package";
            type = lib.types.nullOr lib.types.package;
            default = pkgs.papirus-icon-theme;
          };
        };

        font = {
          serif = lib.mkOption {
            description = "Font name";
            type = lib.types.str;
            default = config.fonts.fontconfig.defaultFonts.serif |> lib.head;
          };
          mono = lib.mkOption {
            description = "Monospace font";
            type = lib.types.str;
            default = config.fonts.fontconfig.defaultFonts.monospace |> lib.head;
          };
          sansSerif = lib.mkOption {
            description = "Sans Serif font";
            type = lib.types.str;
            default = config.fonts.fontconfig.defaultFonts.sansSerif |> lib.head;
          };
          size = lib.mkOption {
            description = "Font size";
            type = lib.types.int;
            default = 14;
            apply = toString;
          };

          package = lib.mkOption {
            description = "Font package";
            type = lib.types.nullOr lib.types.package;
            default = self'.legacyPackages.apple-font;
          };
        };
      };
    };
}
