{
  exo.core =
    {
      config,
      constants,
      lib,
      ...
    }:
    let
      cfg = config.forte.persist;
    in
    {
      config = {
        fileSystems."/nix".neededForBoot = true;
        fileSystems."/persist".neededForBoot = true;

        fileSystems."/var/lib/nixos" = {
          device = "/persist/var/lib/nixos";
          fsType = "none";
          options = [ "bind" ];
          neededForBoot = true;
        };
        fileSystems."/etc/machine-id" = {
          device = "/persist/etc/machine-id";
          fsType = "none";
          options = [ "bind" ];
          neededForBoot = true;
        };

        systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];

        system.nixos-core.persistence =
          let
            asFile = f: {
              target = f;
              kind = "file";
            };
          in
          {
            enable = true;
            stores."/persist" = {
              commonMountOptions = [ "x-gvfs-hide" ];

              entries =
                lib.unique (
                  [
                    "/var/log"
                    "/var/lib/systemd"
                  ]
                  ++ cfg.root.directories
                )
                ++ map asFile cfg.root.files;

              users.${constants.username} =
                lib.unique (
                  [
                    "Development"
                    "Documents"
                    "NixOS"
                    "Pictures"
                    "Videos"
                    "Downloads"
                  ]
                  ++ cfg.home.directories
                )
                ++ map asFile (lib.unique cfg.home.files);
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
                  isHomePath = p: (if lib.isAttrs p then p.target else p) |> lib.hasPrefix "/home/";
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
