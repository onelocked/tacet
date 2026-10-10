{
  tack.inputs =
    {
      fuzzy-search = "gh:onelocked/fuzzy-search.yazi";
      confirm-dialog = "gh:onelocked/confirm-dialog.yazi";
      extra-metadata = "gh:boydaihungst/file-extra-metadata.yazi";
      no-header-prompt = "gh:onelocked/no-header-prompt.yazi";
      yazbar = "gh:onelocked/yazbar.yazi";
    }
    |> builtins.mapAttrs (
      _: v:
      {
        type = "fetch";
        group = "sxyazi";
      }
      // (if builtins.isString v then { url = v; } else v)
    );

  exo.core =
    {
      pkgs,
      lib,
      scheme,
      inputs,
      ...
    }:
    {
      forte.yazi = {
        plugins = {
          inherit (pkgs.yaziPlugins)
            full-border
            ouch
            lazygit
            git
            piper
            chmod
            smart-filter
            wl-clipboard
            toggle-pane
            ;
        }
        // (
          [
            "fuzzy-search"
            "yazbar"
            "no-header-prompt"
            "confirm-dialog"
            "extra-metadata"
          ]
          |> map (
            name:
            lib.nameValuePair name (
              pkgs.yaziPlugins.mkYaziPlugin {
                pname = name;
                version = "git";
                src = inputs.${name};
              }
            )
          )
          |> lib.listToAttrs
        );
        settings.plugin =
          let
            piper = "piper -- CLICOLOR_FORCE=1 ${lib.getExe pkgs.glow} -w=$w -s=dracula -- $1";
            mk = url: run: { inherit url run; };
            mkFetcher = group: url: run: { inherit group url run; };
          in
          {
            prepend_previewers = [ (mk "*.md" piper) ];
            prepend_preloaders = [ (mk "*.md" piper) ];
            prepend_fetchers = [
              (mkFetcher "simple-tag" "*" "simple-tag")
              (mkFetcher "simple-tag" "*/" "simple-tag")
              (mkFetcher "git" "*" "git")
              (mkFetcher "git" "*/" "git")
            ];
            append_previewers = [
              (mk "*" ''piper -- ${lib.getExe pkgs.hexyl} --border=none --terminal-width=$w "$1"'')
            ];
          };

        keymap = {
          mgr.prepend_keymap =
            let
              mkKeymap = on: run: desc: { inherit on run desc; };
            in
            [
              (mkKeymap [ "<Enter>" ] "plugin confirm-dialog" "Safe open in chooser mode")
              (mkKeymap [ "t" "s" ] "plugin toggle-pane min-parent" "Show or hide the parent pane")
              (mkKeymap [ "z" ] "plugin fuzzy-search -- fd --TL=3" "Fuzzy Find Files")
              (mkKeymap [ "<S-s>" ] "plugin fuzzy-search -- rg --TL=3" "Ripgrep Search")
              (mkKeymap [ "<S-z>" ] "plugin fuzzy-search -- zoxide --TL=3" "Zoxide Search")
              (mkKeymap [ "c" "m" ] "plugin chmod" "chmod on files")
              (mkKeymap [ "C" ] "plugin ouch" "Compress files with ouch")
              (mkKeymap [ "f" ] "plugin smart-filter" "Smart filter")
              (mkKeymap [ "<C-y>" ] "plugin wl-clipboard" "copy to clipboard")
            ];
        };
      };
      forte.yazi.initLua =
        with scheme; # lua
        ''
          require("no-header-prompt"):setup()
          require("full-border"):setup {
          	type = ui.Border.PLAIN,
          }
          require("git"):setup {
              -- Order of status signs showing in the linemode
            order = 1500,
          }
          require("yazbar"):setup({
            color = "${base0D}",               -- blue (active/primary)
            secondary_color = "${base02}",     -- selection background
            default_files_color = "${base04}", -- dark foreground (inactive)
            selected_files_color = "${base05}",-- default foreground
            yanked_files_color = "${base0B}",  -- green
            cut_files_color = "${base08}",     -- red

            separator_style = "liney", -- "angly" | "curvy" | "liney" | "empty"

            select_symbol = "",
            yank_symbol = "󰆐",

            permissions_style = "octal", -- can be either "octal" or "rwx"

            filename_max_length = 24, -- truncate when filename > 24
            filename_truncate_length = 6, -- leave 6 chars on both sides
            filename_truncate_separator = "..."
          })
        '';
    };
}
