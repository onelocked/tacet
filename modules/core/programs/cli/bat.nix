{
  exo.core =
    {
      pkgs,
      wrapPackage,
      lib,
      config,
      ...
    }:
    let
      cfg = config.forte.bat;
    in
    {
      config = lib.mkIf cfg.enable {
        hj.packages = [ cfg.package ];
        environment.shellAliases = {
          cat = "${cfg.package}/bin/bat";
        };
      };
      options.forte.bat = {
        enable = lib.mkEnableOption "bat" // {
          default = true;
        };
        package = lib.mkOption {
          type = lib.types.package;
          default = wrapPackage {
            package = pkgs.bat;
            args = [
              "--theme=TwoDark"
              "--style=plain"
            ];
          };
        };
      };
    };
}
