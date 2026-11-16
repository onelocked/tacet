{ config, ... }:
{
  exo.configurations = {
    oracle = {
      user = "onelock";
      hardware = "oracle";
      server = true;
      theme = "light";
      modules = with config.exo.mods; [ three-x-ui ];
      extraConfig =
        { pkgs, ... }:
        {
          sops.defaultSopsFile = ../../../.secrets/vps.yaml;
          boot.kernelPackages = pkgs.linuxPackages_latest;
        };
    };
  };
  exo.hardware.oracle =
    { modulesPath, ... }:
    {
      imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
      boot.initrd.availableKernelModules = [
        "ata_piix"
        "uhci_hcd"
        "virtio_pci"
        "virtio_scsi"
        "sd_mod"
        "virtio_blk"
        "sr_mod"
        "usbhid"
        "nvme"
      ];

      boot.loader.grub = {
        enable = true;
        efiSupport = true;
        efiInstallAsRemovable = true;
      };
      boot.kernelModules = [ "kvm-amd" ];

      systemd.network.enable = false;
      networking = {
        useDHCP = true;
        dhcpcd.enable = true;
        useNetworkd = false;
      };
    };
  exo.disko.oracle = {
    boot.tmp.cleanOnBoot = true;
    boot.tmp.useTmpfs = false;

    boot.kernel.sysctl = {
      "vm.swappiness" = 30;
    };

    disko.devices.nodev = {
      "/" = {
        fsType = "tmpfs";
        mountOptions = [
          "size=2G"
          "defaults"
          "mode=755"
        ];
      };
    };

    disko.devices.disk.nixos = {
      device = "/dev/sda";
      type = "disk";
      content.type = "gpt";

      content.partitions.boot = {
        name = "boot";
        size = "1M";
        type = "EF02";
      };

      content.partitions.esp = {
        name = "ESP";
        size = "500M";
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
                swapfile.size = "4G";
              };
            };

            "@tmp" = {
              mountpoint = "/tmp";
              mountOptions = [
                "noatime"
                "compress=zstd"
              ];
            };
          };
        };
      };
    };
  };
}
