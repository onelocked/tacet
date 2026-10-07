{
  exo.core = {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableFishIntegration = false;
      settings = {
        global = {
          hide_env_diff = true;
        };
      };
    };
    forte.persist.home.directories = [ ".local/share/direnv" ];
  };
}
