{
  exo.mods.desktop =
    { pkgs, lib, ... }:
    {
      config = {
        hardware.graphics.enable = true;

        services.displayManager.enable = lib.mkForce false;

        services.gvfs.enable = false;

        services.scx-loader = {
          enable = true;
          package = pkgs.scx.rustscheds;
          config.scheduler = "scx_cake"; # 🎂
        };

        programs.seahorse.enable = false;
        services.gnome.gnome-keyring.enable = true;
        security.pam.services.login.enableGnomeKeyring = true;
        forte.persist.home.directories = [ ".local/share/keyrings" ];

        hj.environment.sessionVariables = {
          APP2UNIT_SLICES = "a=app-graphical.slice b=background-graphical.slice s=session-graphical.slice";
          APP2UNIT_TYPE = "service";
          NIXOS_OZONE_WL = "1";
        };

        hj.packages = with pkgs; [
          silicon
          wl-clipboard
          app2unit
        ];
      };
    };
}
