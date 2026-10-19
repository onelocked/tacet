{
  exo.mods.gaming =
    { constants, ... }:
    {
      forte.gaming = {
        enable = true;
        ntsync.enable = true;
        platformOptimizations.enable = true;
        gamemode.enable = true;
      };
      # Realtime scheduling permissions for games
      # Required because Steam runs in bubblewrap sandbox where capabilities don't work
      security.pam.loginLimits = [
        {
          domain = "@gamemode";
          item = "nice";
          type = "-";
          value = "-20";
        }
        {
          domain = constants.username;
          item = "rtprio";
          type = "-";
          value = "98";
        }
        {
          domain = constants.username;
          item = "nice";
          type = "-";
          value = "-20";
        }
        {
          domain = constants.username;
          item = "memlock";
          type = "-";
          value = "unlimited";
        }
      ];
    };

  exo.skeleton =
    {
      pkgs,
      lib,
      constants,
      config,
      ...
    }:
    let
      cfg = config.forte.gaming;
    in
    {
      config =
        lib.mkIf cfg.enable
        <| lib.mkMerge [
          {
            preservation = {
              preserveAt = {
                "/steam" = {
                  commonMountOptions = [ "x-gvfs-hide" ];
                  users.${constants.username} = {
                    directories = (
                      lib.unique [
                        ".local/share/vulkan"
                        ".cache/winetricks"
                        ".cache/umu-protonfixes"
                        ".cache/mesa_shader_cache"
                        ".local/share/dxvk-cache"
                      ]
                      ++ lib.optionals config.programs.steam.enable [
                        ".steam"
                        ".local/share/Steam"
                      ]
                      ++ lib.optionals (builtins.elem "nvidia" config.services.xserver.videoDrivers) [
                        ".nv"
                        ".cache/nvidia"
                      ]
                    );
                  };
                };
              };
            };
            systemd.tmpfiles.settings.preservation = {
              "/steam".d = {
                user = constants.username;
                group = "users";
                mode = "0755";
              };
              "/games".d = {
                user = constants.username;
                group = "users";
                mode = "0755";
              };
            };

            forte.allowUnfree = [
              "steam"
              "steam-unwrapped"
            ];
          }
          (lib.mkIf cfg.gamemode.enable {
            programs.gamemode = {
              enable = true;
              settings = {
                general = {
                  softrealtime = "auto";
                  renice = 15;
                };
                cpu = {
                  park_cores = "0,1";
                  pin_cores = "2,3,4,5,6,7";
                  governor = "performance";
                  energy_perf_preference = "performance";
                };
                custom = {
                  start = "${config.forte.quickshell.package}/bin/tuishell ipc call gamemode set 1";
                  end = "${config.forte.quickshell.package}/bin/tuishell ipc call gamemode set 0";
                };
              };
            };
          })
          (lib.mkIf cfg.ntsync.enable {
            # support driver for emulation of NT synchronization, used by Wine/Proton
            boot.kernelModules = [ "ntsync" ];
            services.udev.packages = [
              (pkgs.writeTextFile {
                name = "ntsync-udev-rules";
                text = ''KERNEL=="ntsync", MODE="0660", TAG+="uaccess"'';
                destination = "/etc/udev/rules.d/70-ntsync.rules";
              })
            ];
          })
          (lib.mkIf cfg.platformOptimizations.enable {
            boot.extraModprobeConfig = # bash
              "options nvidia NVreg_UsePageAttributeTable=1 ";

            boot.kernelParams = [
              "pcie_aspm=off" # disables PCIe Active State Power Management (ASPM) across all PCIe links on the system
              "nowatchdog" # Disables the software watchdog, freeing up a tiny bit of CPU time
              "nmi_watchdog=0" # Disables the NMI watchdog

              "transparent_hugepage=madvise"
              "thp_anon=madvise"

              "hpet=disable" # Kill the High Precision Event Timer
              "intel_idle.max_cstate=1"
            ];
            boot.kernel.sysctl = {
              "kernel.sched_cfs_bandwidth_slice_us" = 3000;
              "net.ipv4.tcp_fin_timeout" = 5;
              "vm.max_map_count" = 2147483642;

              # Prevent background writeback micro-stutters
              "vm.dirty_ratio" = 10;
              "vm.dirty_background_ratio" = 5;

              "vm.compaction_proactiveness" = 0;
              "vm.vfs_cache_pressure" = 20;
              "vm.watermark_boost_factor" = 0;
              "vm.watermark_scale_factor" = 125;

              "vm.page-cluster" = 0;
              "vm.stat_interval" = 10;
            };
          })
        ];
      options.forte.gaming = {
        enable = lib.mkEnableOption "Gaming";
        ntsync.enable = lib.mkEnableOption "NTSync support";
        gamemode.enable = lib.mkEnableOption "Gamemode with config";
        platformOptimizations.enable = lib.mkEnableOption "Platform optimizations";
      };
    };
}
