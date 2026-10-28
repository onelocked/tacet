{
  exo.core =
    { scheme, ... }:
    {
      systemd.tmpfiles.rules = [
        "z /sys/class/powercap/intel-rapl/intel-rapl:0/energy_uj 0444 root root - -"
      ];
      forte.btop = {
        enable = true;
        settings = {
          color_theme = "oneshill";
          vim_keys = true;
          rounded_corners = false;
          proc_tree = false;
          proc_gradient = false;
          show_gpu_info = "on";
          show_uptime = true;
          show_coretemp = true;
          theme_background = false;
          cpu_single_graph = true;
          show_disks = true;
          show_swap = true;
          swap_disk = false;
          use_fstab = false;
          only_physical = false;
          shown_boxes = "cpu mem net proc gpu0";
          gpu_mirror_graph = false;
        };
        themes = {
          oneshill =
            with scheme; # bash
            ''
              theme[main_bg]="${base00}"
              theme[main_fg]="${base07}"
              theme[title]="${base0D}"
              theme[hi_fg]="${base08}"
              theme[selected_bg]="${base02}"
              theme[selected_fg]="${base07}"
              theme[inactive_fg]="${base03}"
              theme[proc_misc]="${base0C}"
              theme[cpu_box]="${base0D}"
              theme[mem_box]="${base0D}"
              theme[net_box]="${base0D}"
              theme[proc_box]="${base0E}"
              theme[div_line]="${base03}"
              theme[temp_start]="${base0B}"
              theme[temp_mid]="${base09}"
              theme[temp_end]="${base08}"
              theme[cpu_start]="${base0D}"
              theme[cpu_mid]="${base0C}"
              theme[cpu_end]="${base0E}"
              theme[free_start]="${base0B}"
              theme[free_mid]="${base14}"
              theme[free_end]="${base0C}"
              theme[cached_start]="${base0A}"
              theme[cached_mid]="${base09}"
              theme[cached_end]="${base0F}"
              theme[available_start]="${base0C}"
              theme[available_mid]="${base15}"
              theme[available_end]="${base0D}"
              theme[used_start]="${base0E}"
              theme[used_mid]="${base12}"
              theme[used_end]="${base08}"
              theme[download_start]="${base0D}"
              theme[download_mid]="${base15}"
              theme[download_end]="${base0C}"
              theme[upload_start]="${base0E}"
              theme[upload_mid]="${base17}"
              theme[upload_end]="${base12}"
            '';
        };
      };
    };

  perSystem =
    { pkgs, ... }:
    {
      remotePackages.btop = pkgs.btop.overrideAttrs (oldAttrs: {
        doCheck = false;
        patches = (oldAttrs.patches or [ ]) ++ [
          (pkgs.fetchpatch2 {
            name = "normalize_processes";
            url = "https://raw.githubusercontent.com/NotAShelf/nyxexprs/refs/heads/main/pkgs/btop/patches/normalize_processes.patch";
            hash = "sha256-dh3TTb0Ix983W50inTzGflQ7mpBELaKReBUmzjBixTo=";
          })
        ];
      });
    };
  exo.skeleton =
    {
      lib,
      wrapPackage,
      config,
      self',
      ...
    }:
    let
      cfg = config.forte.btop;
    in
    {
      config = lib.mkIf (cfg.enable) { hj.packages = [ cfg.package ]; };

      options.forte.btop = {
        enable = lib.mkEnableOption "btop";

        settings = lib.mkOption {
          type = lib.types.attrs;
          default = { };
        };

        themes = lib.mkOption {
          type = lib.types.attrs;
          default = { };
        };

        package = lib.mkOption {
          default =
            let
              toBtopConf = lib.generators.toKeyValue {
                mkKeyValue = lib.generators.mkKeyValueDefault {
                  mkValueString =
                    v:
                    if builtins.isBool v then
                      (if v then "True" else "False")
                    else if builtins.isString v then
                      ''"${v}"''
                    else
                      toString v;
                } " = ";
              };
            in
            wrapPackage {
              package = self'.packages.btop;
              files.configuration = {
                "btop.conf" = cfg.settings |> toBtopConf;
              }
              // (cfg.themes |> lib.mapAttrs' (name: content: lib.nameValuePair "themes/${name}.theme" content));
              args = [
                "--config ${wrapPackage.out'}/configuration/btop.conf"
                "--themes-dir ${wrapPackage.out'}/configuration/themes"
              ];
            };
        };
      };
    };
  exo.mods.desktop =
    { lib, config, ... }:
    let
      cfg = config.forte.btop;
    in
    {
      config = lib.mkIf cfg.enable { forte.xdg.desktopEntries."btop".noDisplay = true; };
    };
}
