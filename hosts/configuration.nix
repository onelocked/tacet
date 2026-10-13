{
  lib,
  config,
  withSystem,
  mkScheme,
  ...
}:
{
  config = {
    flake.nixosConfigurations =
      config.exo.configurations
      |> lib.mapAttrs (
        hostName: hostConfig:
        withSystem hostConfig.system (
          {
            self',
            inputs',
            inputs,
            packages',
            rootPath,
            ...
          }:
          lib.nixosSystem {
            specialArgs = {
              inherit
                inputs
                self'
                inputs'
                packages'
                rootPath
                hostName
                ;
              inherit (hostConfig) hardware theme server;
              scheme = mkScheme config.schemes.${hostConfig.theme};
              constants = {
                username = hostConfig.user;
                homedir = "/home/${hostConfig.user}";
              };
            };
            modules =
              hostConfig.modules
              ++ [
                {
                  networking.hostName = lib.mkDefault hostName;
                  nixpkgs.hostPlatform = lib.mkDefault hostConfig.system;
                }
              ]
              ++ lib.optionals (!hostConfig.bare) (
                [
                  inputs.disko.nixosModules.disko
                  config.exo.skeleton
                  config.exo.core
                  config.exo.hardware.${hostConfig.hardware}
                  config.exo.disko.${hostConfig.hardware}
                  hostConfig.extraConfig
                ]
                ++ lib.optional (!hostConfig.server) config.exo.mods.desktop
                ++ lib.optional hostConfig.server { environment.variables.TERM = "xterm-256color"; }
              );
          }
        )
      );
    exo.core =
      {
        config,
        constants,
        server,
        ...
      }:
      let
        password = config.sops.secrets."linux-password".path;
      in
      {
        sops.secrets."linux-password".neededForUsers = true; # Required for pre-user-creation
        users = {
          mutableUsers = false;
          users.${constants.username} = {
            hashedPasswordFile = password;
            isNormalUser = true;
            useDefaultShell = true;
            extraGroups = [
              "wheel" # Always keep wheel for sudo access
            ]
            ++ lib.optionals (!server) [
              "networkmanager"
              "kvm"
              "input"
              "disk"
              "libvirtd"
              "video"
              "audio"
            ];
          };
        };
      };
    perSystem = { pkgs, ... }: { formatter = pkgs.nixfmt-rs; };
  };

  options = {
    perSystem = lib.mkOption { type = lib.types.deferredModule; };
    flake = lib.mkOption { type = lib.types.lazyAttrsOf lib.types.unspecified; };

    systems = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "x86_64-linux"
        "aarch64-linux"
      ];
    };
    exo = {
      core = lib.mkOption { type = lib.types.deferredModule; };
      skeleton = lib.mkOption { type = lib.types.deferredModule; };
      mods = lib.mkOption { type = lib.types.lazyAttrsOf lib.types.deferredModule; };
      hardware = lib.mkOption { type = lib.types.lazyAttrsOf lib.types.deferredModule; };
      disko = lib.mkOption { type = lib.types.lazyAttrsOf lib.types.deferredModule; };

      configurations = lib.mkOption {
        description = "NixOS Configuration";
        default = { };
        type = lib.types.attrsOf (
          lib.types.submodule (
            { hostName, ... }:
            {
              options = {
                system = lib.mkOption {
                  type = lib.types.str;
                  default = "x86_64-linux";
                  description = "The architecture of the system.";
                };

                user = lib.mkOption {
                  type = lib.types.str;
                  default = throw "Configuration failed: You must define a `user` for the host '${hostName}'.";
                  description = "The primary user for this system";
                };

                hardware = lib.mkOption {
                  type = lib.types.str;
                  default = throw "Configuration failed: You must define a `hardware` profile for the host '${hostName}'.";
                  description = "The hardware and disko profile for this system";
                };

                theme = lib.mkOption {
                  type = lib.types.enum (lib.attrNames config.schemes);
                  default = "dark";
                  description = "The color theme for this system";
                };

                server = lib.mkEnableOption "Enable server mode";

                bare = lib.mkEnableOption "Enable bare mode, no modules are imported";

                modules = lib.mkOption {
                  type = lib.types.listOf lib.types.deferredModule;
                  default = [ ];
                  description = "List of modules to include";
                };

                extraConfig = lib.mkOption {
                  type = lib.types.deferredModule;
                  default = { };
                  description = "configurations specific to this host";
                };
              };
            }
          )
        );
      };
    };
  };
}
