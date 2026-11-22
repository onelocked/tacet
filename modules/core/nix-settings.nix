{
  tack.inputs = {
    nixpkgs = {
      url = "gh:nixos/nixpkgs/nixos-unstable";
      group = "nix";
    };
    disko = {
      url = "gh:nix-community/disko";
      group = "nix";
    };
    systems = {
      url = "gh:nix-systems/default-linux";
      group = "nix";
    };
  };
  exo.core =
    {
      pkgs,
      lib,
      constants,
      config,
      ...
    }:
    {
      system.stateVersion = "25.11";
      nix = {
        channel.enable = false; # required for nix-shell -p to work, set it to true if needed
        optimise.automatic = true;
        package = pkgs.nixVersions.latest;
        settings = {
          allow-import-from-derivation = false;
          trusted-users = [ constants.username ];
          # Binary Cache
          substituters = [ "https://onelock.cachix.org" ];
          trusted-public-keys = [ "onelock.cachix.org-1:Wyy9XrWqFKcPxkZXQg5yZXtsbKTbkaga44UWRJfgqEg=" ];
          experimental-features = [
            "nix-command"
            "flakes"
            "pipe-operators"
          ];
          auto-optimise-store = true;
          use-xdg-base-directories = true;
          warn-dirty = false;
          keep-outputs = true;
          keep-derivations = true;
        };
        extraOptions = "!include ${config.sops.secrets.nix_extra_config.path}";
      };
      sops.secrets.nix_extra_config.owner = constants.username;
      programs.nano.enable = lib.mkForce false;
      nixpkgs = {
        config = {
          allowUnfree = false;
          allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) config.forte.allowUnfree;
        };
      };

      environment.systemPackages = [ pkgs.nix-output-monitor ];

      programs.fish.shellAbbrs = {
        nb = "nom build";
        nd = "nix develop";
        nr = "nix run";
        tr = "nix run .#tack-rebuild";
      };
    };

  exo.mods.desktop = {
    forte.xdg.desktopEntries."nixos-manual".noDisplay = true;
  };
  exo.skeleton =
    { lib, ... }:
    {
      options.forte.allowUnfree = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };
    };
}
