{
  exo.mods.desktop =
    {
      constants,
      config,
      wrapPackage,
      inputs',
      theme,
      ...
    }:
    {
      # Kitty remote control password for kitty-scrollback.nvim.
      sops.secrets.kitty = {
        owner = constants.username;
        mode = "0400";
      };
      sops.templates."kitty-rc.conf" = {
        owner = constants.username;
        content = ''
          remote_control_password "${
            config.sops.placeholder."kitty"
          }" focus-window get-text send-text signal-child get-colors ls launch close-window kitten
        '';
      };
      forte.kitty.settings.include = config.sops.templates."kitty-rc.conf".path;
      forte.neovim.package = wrapPackage {
        package = inputs'.nitovim.packages.${theme};
        runShell = [
          ''export KITTY_RC_PASSWORD="$(cat ${config.sops.secrets.kitty.path} 2>/dev/null || true)"''
        ];
      };
    };
}
