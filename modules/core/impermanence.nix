{
  tack.inputs.preservation = {
    url = "gh:nix-community/preservation";
    group = "nix";
  };
  exo.core =
    {
      config,
      constants,
      lib,
      inputs,
      ...
    }:
    let
      cfg = config.forte.persist;
    in
    {
      imports = [ inputs.preservation.nixosModules.default ];
      # setup persistence
      config = {
        fileSystems."/nix".neededForBoot = true;
        fileSystems."/persist".neededForBoot = true;

        systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];
        security.sudo-rs.extraConfig = ''Defaults lecture="never" ''; # shut up sudo

        preservation = {
          enable = true;
          preserveAt = {
            "/persist" = {
              commonMountOptions = [ "x-gvfs-hide" ];
              files = [
                {
                  file = "/etc/machine-id";
                  inInitrd = true;
                }
              ]
              ++ cfg.root.files;
              directories = lib.unique (
                [
                  "/var/lib/nixos" # for persisting user uids and gids
                  "/var/log" # logs
                  "/var/lib/systemd"
                ]
                ++ cfg.root.directories
              );

              users.${constants.username} = {
                files = lib.unique cfg.home.files;
                directories = lib.unique (
                  [
                    "Development"
                    "Documents"
                    "NixOS"
                    "Pictures"
                    "Videos"
                    "Downloads"
                  ]
                  ++ cfg.home.directories
                );
              };
            };
          };
        };
      };
      options.forte = {
        persist = {
          root =
            let
              assertNoHomeDirs =
                paths:
                let
                  isHomePath = p: (if lib.isAttrs p then p.file else p) |> lib.hasPrefix "/home/";
                in
                assert lib.assertMsg (!(paths |> lib.any isHomePath)) "/home used in a root persist!";
                paths;
            in
            {
              directories = lib.mkOption {
                type = lib.types.listOf lib.types.anything;
                default = [ ];
                apply = assertNoHomeDirs;
                description = "Directories to persist in root filesystem";
              };
              files = lib.mkOption {
                type = lib.types.listOf lib.types.anything;
                default = [ ];
                apply = assertNoHomeDirs;
                description = "Files to persist in root filesystem";
              };
            };
          home = {
            directories = lib.mkOption {
              type = lib.types.listOf lib.types.anything;
              default = [ ];
              description = "Directories to persist in home directory";
            };
            files = lib.mkOption {
              type = lib.types.listOf lib.types.anything;
              default = [ ];
              description = "Files to persist in home directory";
            };
          };
        };
      };
    };
}
