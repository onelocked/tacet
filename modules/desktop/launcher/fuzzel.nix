{
  exo.mods.desktop =
    {
      pkgs,
      config,
      ...
    }:
    {
      forte.fuzzel = {
        enable = false;
        settings = {
          main = {
            dpi-aware = "yes";
            width = 25;
            letter-spacing = 0;
            font = "Liga SFMono:weight=500:style=Bold:width=expanded:size=15";
            namespace = "fuzzel";
            icon-theme = "${config.forte.gtk.icons.name}";
            terminal = "${pkgs.foot}/bin/foot -e";
          };
          colors = {
            background = "131316CC";
            text = "e5e1e6ff";
            prompt = "c7c4dcff";
            placeholder = "ebb9d0ff";
            input = "c5c0ffff";
            match = "ebb9d0ff";
            selection = "c5c0ff80";
            selection-text = "e5e1e6ff";
            selection-match = "2a2277ff";
            counter = "c7c4dcff";
            border = "c5c0ffff";
          };
        };
      };
    };
  exo.skeleton =
    {
      lib,
      wrapPackage,
      pkgs,
      config,
      ...
    }:
    let
      cfg = config.forte.fuzzel;
    in
    {
      config = lib.mkIf cfg.enable {
        hj.packages = [ cfg.package ];
      };
      options.forte.fuzzel = {
        enable = lib.mkEnableOption "fuzzel";
        settings = lib.mkOption {
          type = lib.types.attrs;
          default = { };
        };
        package = lib.mkOption {
          type = lib.types.package;
          default = wrapPackage {
            package = pkgs.fuzzel;
            files."configuration/fuzzel.ini" = wrapPackage.ini cfg.settings;
            args = [
              "--config"
              "${wrapPackage.out}/configuration/fuzzel.ini"
            ];
          };
        };
      };
    };
}
