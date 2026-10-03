{ config, ... }:
{
  exo.configurations = {
    firekeeper = {
      user = "onelock";
      hardware = "firekeeper";
      theme = "monochrome";
      modules = with config.exo.mods; [
        neovim
        media
        remote-access
        cachyos-kernel
      ];
      extraConfig =
        { lib, ... }:
        {
          forte.openssh.enable = lib.mkForce false;
          forte.opkssh.enable = true;
          sops.defaultSopsFile = ../../.secrets/personal.yaml;
          forte.jellyfin-tui.enable = false;

          forte.persist.home.directories = [
            ".ssh"
            ".local/share/.gnupg"
          ];

          forte.hyprland.lua.settings = # lua
            ''
              hl.monitor({
                output   = "HDMI-A-1",
                mode     = "3440x1440@100",
                position = "0x0",
                scale    = "1",
                bitdepth = 10,
              })
            '';

          hj.files.".ssh/config".text = # bash
            ''
              Host Raspberry
                User onelock
                HostName 192.168.1.239

              Host gitea.onelock.org
                Port 2222
                IdentitiesOnly yes
                User git
                HostName gitea.onelock.org
                IdentityFile ~/.ssh/id_ed25519_gitea

              Host github.com
                IdentitiesOnly yes
                User git
                HostName github.com
                IdentityFile ~/.ssh/id_ed25519_github

              Host router
                User root
                HostName 192.168.1.1

              Host lucatiel
                User onelock
                HostName 10.13.37.216
                IdentityFile ~/.ssh/shorekeeper

              Host shorekeeper
                User onelock
                HostName vps.onelock.org
                LocalForward 2053 127.0.0.1:2053
                IdentityFile ~/.ssh/shorekeeper

              Host *
                IdentitiesOnly yes
            '';
        };
    };
  };
  exo.hardware.firekeeper =
    {
      self',
      modulesPath,
      lib,
      config,
      ...
    }:
    {
      imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

      powerManagement = {
        enable = true;
        cpuFreqGovernor = "ondemand";
        cpufreq.min = 800000;
      };

      boot.kernelModules = [
        "amd_pstate"
        "kvm-amd"
      ];
      boot.kernelParams = [ "amd_pstate=active" ];
      hardware.enableRedistributableFirmware = true;
      nixpkgs.config.rocmSupport = true;
      hardware.amdgpu.opencl.enable = true;
      boot.initrd.kernelModules = [ "amdgpu" ];
      boot.initrd.availableKernelModules = [
        "nvme"
        "xhci_pci"
        "usb_storage"
        "usbhid"
        "sd_mod"
      ];
      networking.interfaces.eno1.wakeOnLan.enable = true;
      hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

      hj.packages = [ self'.packages.amdgpu_top ];
    };

  exo.disko.firekeeper = {
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
  };
  perSystem =
    { pkgs, ... }:
    {
      remotePackages.amdgpu_top = pkgs.amdgpu_top.overrideAttrs (old: {
        doCheck = false;
        cargoBuildFlags = (old.cargoBuildFlags or [ ]) ++ [
          "--no-default-features"
          "--features"
          "tui,libamdgpu_top/libdrm_link"
        ];
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];
        postInstall = (old.postInstall or "") + ''
          makeWrapper $out/bin/amdgpu_top $out/bin/gtop \
            --add-flags '--dark'
        '';
      });
    };
}
