{
  exo.mods.opencode = { pkgs, ... }: {
    hj.packages = [ pkgs.opencode ];
    forte.persist.home.directories = [
      ".config/opencode"
      ".local/share/opencode"
      ".local/state/opencode"
      ".cache/opencode"
    ];
  };
}
