{
  exo.mods.desktop =
    { lib, ... }:
    {
      xdg = {
        portal = {
          enable = true;
          xdgOpenUsePortal = false;
          wlr.enable = false;
          config = {
            common = {
              default = lib.mkForce [ "gtk" ];
              "org.freedesktop.impl.portal.Secret" = lib.mkForce [ "gnome-keyring" ];
              "org.freedesktop.impl.portal.Chooser" = lib.mkForce [ "none" ];
              "org.freedesktop.impl.portal.AppChooser" = lib.mkForce [ "gtk" ];
            };
          };
        };
        terminal-exec.enable = true;
      };
      environment.sessionVariables = {
        GTK_USE_PORTAL = "0";
      };
    };
}
