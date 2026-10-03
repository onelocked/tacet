{
  exo.mods.desktop =
    {
      lib,
      config,
      self',
      ...
    }:
    let
      cfg = config.forte.cursor;
    in
    {
      config = {
        forte.cursor = {
          name = "Bibata-Modern-Classic";
          size = 28;
          package = self'.legacyPackages.cursors.hypr-bibata-classic;
        };
        hj.packages = [ cfg.package ];
        hj.environment.sessionVariables = {
          XCURSOR_SIZE = cfg.size;
          XCURSOR_THEME = cfg.name;
          HYPRCURSOR_THEME = cfg.name;
          HYPRCURSOR_SIZE = cfg.size;
        };
      };

      options.forte.cursor = {
        name = lib.mkOption {
          description = "Cursor theme";
          type = lib.types.str;
          default = "Bibata-Modern-Ice";
        };

        size = lib.mkOption {
          description = "Cursor size";
          type = lib.types.int;
          default = 28;
          apply = toString;
        };

        package = lib.mkOption {
          description = "Cursor theme package";
          type = lib.types.nullOr lib.types.package;
          default = self'.legacyPackages.cursors.hypr-bibata-ice;
        };
      };
    };
  perSystem =
    { pkgs, ... }:
    {
      legacyPackages = {
        cursors = {
          hypr-bibata-ice = pkgs.symlinkJoin {
            name = "Bibata-Modern-Ice-Merged";
            paths = [
              pkgs.bibata-cursors
              (pkgs.stdenvNoCC.mkDerivation {
                name = "Bibata-Modern-Ice-Hyprcursor";
                src = pkgs.fetchzip {
                  url = "https://github.com/LOSEARDES77/Bibata-Cursor-hyprcursor/releases/download/1.0/hypr_Bibata-Modern-Ice.tar.gz";
                  hash = "sha256-Ji5gqIBrAtFO3S9fCrY/LXPaq5gCY4CkxZJ1uAcjj70=";
                  stripRoot = false;
                };
                dontBuild = true;
                installPhase = ''
                  mkdir -p $out/share/icons/Bibata-Modern-Ice
                  cp -r . $out/share/icons/Bibata-Modern-Ice
                '';
              })
            ];
          };

          hypr-bibata-classic = pkgs.symlinkJoin {
            name = "Bibata-Modern-Classic-Merged";
            paths = [
              pkgs.bibata-cursors
              (pkgs.stdenvNoCC.mkDerivation {
                name = "Bibata-Modern-Classic-Hyprcursor";
                src = pkgs.fetchzip {
                  url = "https://github.com/LOSEARDES77/Bibata-Cursor-hyprcursor/releases/download/1.0/hypr_Bibata-Modern-Classic.tar.gz";
                  hash = "sha256-Uv+96EieGBq6cJNWjoJEHPy/MshbHts+OBow7rWgBSM=";
                  stripRoot = false;
                };
                dontBuild = true;
                installPhase = ''
                  mkdir -p $out/share/icons/Bibata-Modern-Classic
                  cp -r . $out/share/icons/Bibata-Modern-Classic
                '';
              })
            ];
          };
        };
      };
    };
}
