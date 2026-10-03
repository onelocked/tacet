{
  exo.core =
    { scheme, ... }:
    {
      forte.fastfetch =
        let
          esc = (builtins.fromJSON ''{ "value": "\u001b" }'').value;
        in
        {
          enable = true;
          settings = {
            logo = {
              source = "-";
              type = "raw";
              height = 9;
              width = 20;
              padding = {
                top = 1;
                left = 2;
              };
            };
            display = {
              separator = " ┈➤ ";
            };
            modules = with scheme; [
              {
                type = "title";
                keyWidth = 10;
                format = "         ${esc}[38;2;197;192;255m{1}${esc}[38;2;168;200;240m@${esc}[38;2;200;176;232m{2}${esc}[0m";

              }
              {
                type = "custom";
                format = " ─────────────────────────── ";
              }
              {
                type = "os";
                key = " ";
                keyColor = "${base0C}";
              }
              {
                type = "cpu";
                key = " ";
                keyColor = "${base0E}";
              }
              {
                type = "gpu";
                key = "󰢮 ";
                keyColor = "${base08}";
              }
              {
                type = "memory";
                key = " ";
                keyColor = "${base0B}";
                format = "{1} / {2}";
              }
              {
                type = "wm";
                key = " ";
                keyColor = "${base0D}";
              }
              {
                type = "terminal";
                key = " ";
                keyColor = "${base0A}";
              }
              {
                type = "custom";
                format = " ─────────────────────────── ";
              }
              {
                type = "custom";
                format = "   ${esc}[31m  ${esc}[32m  ${esc}[33m  ${esc}[34m  ${esc}[35m  ${esc}[36m  ${esc}[37m  ${esc}[90m ";

              }
            ];
          };
        };
    };
  exo.skeleton =
    {
      lib,
      wrapPackage,
      pkgs,
      config,
      ...
    }:
    let
      cfg = config.forte.fastfetch;
    in
    {
      config = lib.mkIf cfg.enable {
        hj.packages = [ cfg.package ];
        environment.shellAliases.ff = "kitten icat -n --place 20x20@2x1 --scale-up --align left ${
          (pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/onelocked/images/refs/heads/main/fleet-snowfluff.gif";
            hash = "sha256-Vz6QZrhr5c+ShiHJwxHFeyCXszWFvDjhKFm2CyQNAbo=";
          })
        } | ${lib.getExe cfg.package}";
      };

      options.forte.fastfetch = {
        enable = lib.mkEnableOption "fastfetch";
        package = lib.mkOption {
          type = lib.types.package;
          default = wrapPackage {
            package = pkgs.fastfetch-unwrapped;
            files."config.jsonc" = cfg.settings |> wrapPackage.json;
            args = [ "--config ${wrapPackage.out'}/config.jsonc" ];
          };
        };
        settings = lib.mkOption {
          type = lib.types.json;
          default = { };
          description = "Fastfetch config options";
        };
      };
    };
}
