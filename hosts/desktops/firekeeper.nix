{ config, ... }:
{
  tack.inputs.rclip-sync.url = "gh:onelocked/rclip-sync";
  exo.configurations = {
    firekeeper = {
      user = "onelock";
      hardware = "firekeeper";
      theme = "dark";
      modules = with config.exo.mods; [
        neovim
        media
        remote-access
        cachyos-kernel
      ];
      extraConfig =
        {
          lib,
          inputs',
          pkgs,
          config,
          ...
        }:
        {
          forte.bluetooth.enable = true;
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

          #rclip sync
          sops.secrets."wireguard/rclip-sync/firekeeper" = { };
          networking.wireguard.interfaces."rclip-sync" = {
            ips = [ "10.0.0.1/24" ];
            listenPort = 51820;
            privateKeyFile = config.sops.secrets."wireguard/rclip-sync/firekeeper".path;

            peers = [
              {
                name = "lucatiel";
                publicKey = "R+Dw+BaZ1v39J+r2HrsEuvFTNiDq+JWL//2z9CJqrTg=";
                allowedIPs = [ "10.0.0.2/32" ];
                endpoint = "10.13.37.216:51820";
              }
              {
                name = "dante";
                publicKey = "560//IBBTMUjOzNj65Eec9gXtGV8Roq2cJSp9M0vjRY=";
                allowedIPs = [ "10.0.0.3/32" ];
                endpoint = "192.168.1.209:51820";
              }
            ];
          };
          networking.firewall.allowedTCPPorts = [ 24837 ];
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
                  ip -4 addr show dev rclip-sync | grep -q "inet 10.0.0.1/" && exit 0
                  sleep 1
                done
                echo "rclip-sync interface never came up" >&2
                exit 1
              '';
              ExecStart = "${inputs'.rclip-sync.packages.rclip-sync}/bin/rclip serve --bind 10.0.0.1 --peer 10.0.0.2 --peer 10.0.0.3";
              Restart = "on-failure";
              RestartSec = 5;
            };
          };
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
