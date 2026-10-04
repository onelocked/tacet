{
  exo.core =
    { scheme, ... }:
    {
      forte.starship = {
        enable = true;
        settings = {
          add_newline = false;
          format = "[$directory ](color_green)$character";
          palette = "mocha";
          right_format = "$all";
          command_timeout = 1000;
          character = {
            vimcmd_symbol = "[](color_teal)";
            success_symbol = "[❯](color_teal1)";
            error_symbol = "[](color_red)";
          };
          git_branch = {
            format = "[$symbol$branch(:$remote_branch)](color_teal1)";
            symbol = "󰘬 ";
          };
          git_commit = {
            commit_hash_length = 6;
            tag_symbol = " ";
          };
          git_status = {
            ahead = "  ";
            behind = "  ";
            untracked = " 󰯇 ";
            modified = "  ";
            deleted = "  ";
          };
          directory = {
            read_only = " ";
            truncation_length = 6;
            format = "[$path](color_aqua)";
          };
          golang = {
            format = "[ ](bold cyan)";
          };
          nix_shell = {
            format = "[$symbol$state( ($name))](color_fg0) ";
            impure_msg = "[impure](color_red1)";
            pure_msg = "[pure](color_dark_green)";
            symbol = " ";
          };
          docker_context = {
            symbol = "[󰡨 ](bold sky)";
          };
          palettes.mocha = with scheme; {
            color_fg0 = base05;
            color_bg1 = base01;
            color_bg3 = base03;
            color_blue = base0D;
            color_aqua = base0C;
            color_green = base0B;
            color_dark_green = base14;
            color_teal = base15;
            color_teal1 = base16;
            color_orange = base09;
            color_purple = base0E;
            color_red = base08;
            color_red1 = base12;
            color_yellow = base0A;
            color_pink = base17;
          };
        };
      };
    };
  exo.skeleton =
    {
      pkgs,
      lib,
      config,
      wrapPackage,
      ...
    }:
    let
      cfg = config.forte.starship;
      tomlFormat = pkgs.formats.toml { };
    in
    {
      options.forte.starship = {
        enable = lib.mkEnableOption "starship";
        settings = lib.mkOption {
          inherit (tomlFormat) type;
          default = { };
        };
        package = lib.mkOption {
          default = wrapPackage {
            package = pkgs.starship;
            files.configuration."starship.toml" = wrapPackage.toml cfg.settings;
            env.STARSHIP_CONFIG = wrapPackage.out + "configuration/starship.toml";
          };
        };
      };

      config = lib.mkIf cfg.enable {
        hj.packages = [ cfg.package ];
        programs.fish.promptInit = # fish
          ''
            if test "$TERM" != "dumb"
              ${lib.getExe cfg.package} init fish | source
              enable_transience
            end
            # Starship transient prompt
            function starship_transient_prompt_func
              printf " \e[38;2;232;196;216m\e[0m "
            end
          '';
      };
    };
}
