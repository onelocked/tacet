{
  exo.mods.desktop =
    {
      lib,
      constants,
      config,
      ...
    }:
    let
      cfg = config.forte.flatpak;
    in
    {
      config = lib.mkIf cfg.enable {
        services.flatpak.enable = true;
        system.nixos-core.persistence = {
          stores."/games" = {
            commonMountOptions = [ "x-gvfs-hide" ];
            entries = lib.unique [ "/var/lib/flatpak" ];
            users.${constants.username} = lib.unique [
              ".local/share/flatpak"
              ".cache/flatpak"
              ".var/app"
            ];
          };
        };
      };
      options.forte.flatpak = {
        enable = lib.mkEnableOption "Flatpak";
      };
    };
}
