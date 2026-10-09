{ config, ... }:
{
  exo.configurations = {
    lucatiel = {
      user = "onelock";
      hardware = "lucatiel";
      theme = "dark";
      modules = with config.exo.mods; [
        remote-access
        gaming
        neovim
        shadps4
        cachyos-kernel
      ];
      extraConfig =
        {
          config,
          inputs',
          pkgs,
          ...
        }:
        {
          sops.defaultSopsFile = ../../.secrets/personal.yaml;
          forte.flatpak.enable = true;
          forte.kitty.server = false;

          services.nfs.server = {
            enable = true;
            exports = ''
              ${config.hj.directory}/Documents/NFS-Share  192.168.1.185/32(rw,sync,no_subtree_check,no_root_squash)
            '';
          };

          networking.firewall.allowedTCPPorts = [
            2049
            24837
          ];
          forte.hyprland.lua.settings = # lua
            ''
              hl.monitor({
                output = "DP-2",
                mode = "3440x1440@120",
                position = "0x0",
                scale = 1,
                bitdepth = 10,
              })
            '';

          sops.secrets."wireguard/rclip-sync/lucatiel" = { };
          networking.wireguard.interfaces."rclip-sync" = {
            ips = [ "10.0.0.2/24" ];
            listenPort = 51820;
            privateKeyFile = config.sops.secrets."wireguard/rclip-sync/lucatiel".path;

            peers = [
              {
                name = "firekeeper";
                publicKey = "sQM0b16WSVisdSNFofGXGQj/W0D7+PtEebwAP+wuckQ=";
                allowedIPs = [ "10.0.0.1/32" ];
                endpoint = "192.168.1.185:51820";
              }
              {
                name = "dante";
                publicKey = "560//IBBTMUjOzNj65Eec9gXtGV8Roq2cJSp9M0vjRY=";
                allowedIPs = [ "10.0.0.3/32" ];
                endpoint = "192.168.1.209:51820";
              }
            ];
          };
          networking.firewall.allowedUDPPorts = [ 51820 ];

          hj.systemd.services.rclip-sync = {
            description = "rclip-sync LAN clipboard sharing daemon";
            after = [ "graphical-session.target" ];
            partOf = [ "graphical-session.target" ];
            wantedBy = [ "graphical-session.target" ];
            path = [
              pkgs.iproute2
              pkgs.coreutils
              pkgs.gnugrep
            ];
            serviceConfig = {
              Type = "simple";
              ExecStartPre = pkgs.writeShellScript "wait-for-wg" ''
                for i in $(seq 1 30); do
                  ip -4 addr show dev rclip-sync | grep -q "inet 10.0.0.2/" && exit 0
                  sleep 1
                done
                echo "rclip-sync interface never came up" >&2
                exit 1
              '';
              ExecStart = "${inputs'.rclip-sync.packages.rclip-sync}/bin/rclip serve --bind 10.0.0.2 --peer 10.0.0.1 --peer 10.0.0.3";
              Restart = "on-failure";
              RestartSec = 5;
            };
          };
        };
    };
  };

  exo.hardware."lucatiel" =
    {
      config,
      lib,
      modulesPath,
      pkgs,
      ...
    }:
    {
      imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

      boot.initrd.availableKernelModules = [
        "xhci_pci"
        "ahci"
        "nvme"
        "usbhid"
        "usb_storage"
        "sd_mod"
      ];
      boot.kernelModules = [ "kvm-intel" ];

      networking.interfaces.enp6s0.wakeOnLan.enable = true;
      hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

      hardware.graphics = {
        enable32Bit = true;
        extraPackages = with pkgs; [
          nvidia-vaapi-driver
          nv-codec-headers-12
        ];
      };

      hardware.nvidia = {
        branch = "bleeding_edge";
        modesetting.enable = true;
        open = true;
        nvidiaSettings = false;

        powerManagement.enable = true;
        powerManagement.finegrained = false;

        nvidiaPersistenced = false;
      };

      services.xserver.videoDrivers = [ "nvidia" ]; # needed to  have nviida drivers enabled
      forte.allowUnfree = [
        "nvidia-x11"
        "nvidia-kernel-modules"
      ];

      environment.sessionVariables = {
        LIBVA_DRIVER_NAME = "nvidia";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        NVD_BACKEND = "direct";
      };
      services.lact.enable = true; # GPU fan control GUI with a daemon

      forte.persist.root.directories = [ "/etc/lact" ];
    };

  exo.disko.lucatiel = {
    boot.tmp.useTmpfs = true;
    boot.tmp.tmpfsSize = "75%";

    boot.kernel.sysctl = {
      "vm.swappiness" = 1;
    };
    disko.devices.nodev = {
      "/" = {
        fsType = "tmpfs";
        mountOptions = [
          "size=25%"
          "mode=755"
        ];
      };
    };

    disko.devices.disk.nixos = {
      device = "/dev/nvme0n1";
      type = "disk";
      content.type = "gpt";

      content.partitions.esp = {
        name = "ESP";
        size = "1G";
        type = "EF00";

        content = {
          type = "filesystem";
          format = "vfat";
          mountpoint = "/boot";
        };
      };

      content.partitions.root = {
        name = "root";
        size = "100%";

        content = {
          type = "btrfs";
          extraArgs = [ "-f" ];

          subvolumes = {
            "@persist" = {
              mountpoint = "/persist";
              mountOptions = [
                "noatime"
                "compress=zstd"
              ];
            };

            "@nix" = {
              mountpoint = "/nix";
              mountOptions = [
                "noatime"
                "compress=zstd"
              ];
            };

            "@swap" = {
              mountpoint = "/.swapvol";
              mountOptions = [ "noatime" ];
              swap = {
                swapfile.size = "8G";
              };
            };
          };
        };
      };
    };
    disko.devices.disk.storage = {
      device = "/dev/nvme1n1";
      type = "disk";
      content.type = "gpt";

      content.partitions.storage = {
        name = "storage";
        size = "100%";

        content = {
          type = "btrfs";
          extraArgs = [ "-f" ];

          subvolumes = {
            "@steam" = {
              mountpoint = "/steam";
              mountOptions = [
                "noatime"
                "nodatacow"
              ];
            };

            "@games" = {
              mountpoint = "/games";
              mountOptions = [
                "noatime"
                "nodatacow"
              ];
            };
          };
        };
      };
    };
  };
}
