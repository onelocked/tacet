{
  exo.mods.desktop =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.forte.bluetooth;
    in
    {
      config = lib.mkIf cfg.enable {
        services.blueman.enable = true;
        forte.persist.root.directories = [ "/var/lib/bluetooth" ];
        hj.packages = [ pkgs.bluetuith ];
        hardware.bluetooth = {
          enable = true;
          powerOnBoot = true;
          settings.General = {
            Enable = "Source,Sink,Media,Socket";
            Experimental = true;
          };
        };
      };
      options.forte.bluetooth.enable = lib.mkEnableOption "bluetooth";
    };
}
