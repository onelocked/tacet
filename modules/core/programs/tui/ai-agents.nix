{
  exo.mods.opencode = { pkgs, ... }: {
    hj.packages = with pkgs; [
      opencode
      omp
      python3
      libnotify
    ];
    forte.persist.home.directories = [
      ".config/opencode"
      ".local/share/opencode"
      ".local/state/opencode"
      ".cache/opencode"
      ".omp"
    ];
  };
}
