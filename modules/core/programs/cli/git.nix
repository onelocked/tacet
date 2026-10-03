{
  exo.core =
    {
      constants,
      config,
      scheme,
      pkgs,
      ...
    }:
    {
      sops.secrets.email.owner = constants.username;
      sops.templates."git-email" = {
        owner = constants.username;
        content = ''
          [user]
            email = ${config.sops.placeholder."email"}
        '';
      };
      programs.git = {
        enable = true;
        config = {
          include = {
            path = config.sops.templates."git-email".path;
          };
          user = {
            name = "onelocked";
          };
          interactive = {
            diffFilter = "delta --color-only";
          };
          core = {
            editor = "$EDITOR";
            pager = "delta";
            excludesfile = "${pkgs.writeText "gitignore-global" ''
              .envrc
              .direnv
              result*
            ''}";
          };
          delta = {
            navigate = true;
            light = true;
            line-numbers = true;
            hyperlinks = true;
          };
          merge = {
            conflictStyle = "zdiff3";
          };
          diff = {
            colorMoved = "default";
          };
          pager = {
            diff = "diffnav";
            show = "diffnav";
            log = "diffnav";
          };
          init.defaultBranch = "main";
          advice.objectNameWarning = false;
          pull.rebase = true;
          safe.directory = "/tmp";
        };
      };
      forte.lazygit = {
        enable = true;
        withWorktrunk = true;
        settings = with scheme; {
          git = {
            autoFetch = false;
            overrideGpg = true;
            diffRenderers = [
              {
                command = ''delta --file-style "${base0E}" --features space-separated --light --diff-highlight --true-color always --paging=never --line-numbers --hyperlinks --hyperlinks-file-link-format="lazygit-edit://{path}:{line}" --line-fill-method=ansi --navigate --keep-plus-minus-markers --commit-style="${base0B}"'';
              }
              {
                command = ''delta --side-by-side --file-style "${base0E}" --features space-separated --light --diff-highlight --true-color always --paging=never --line-numbers --hyperlinks --hyperlinks-file-link-format="lazygit-edit://{path}:{line}" --line-fill-method=ansi --navigate --keep-plus-minus-markers --commit-style="${base0B}"'';
              }
            ];
            update = {
              days = 365;
              method = "never";
            };
          };

          disableStartupPopups = true;

          gui = {
            showCommandLog = false;
            border = "single";
            authorColors = {
              "*" = base0D;
            };
            expandFocusedSidePanel = true;
            expandedSidePanelWeight = 2;
            filterMode = "fuzzy";
            showFileTree = true;
            showBranchCommitHash = true;
            branchLogGraph = "style";
            showBottomLine = false;
            showNumstatInFilesView = true;
            showPanelJumps = false;
            showRandomTip = false;
            sidePanelWidth = 0.25;
            theme = {
              activeBorderColor = [ base05 ];
              inactiveBorderColor = [ base04 ];
              cherryPickedCommitBgColor = [ base02 ];
              cherryPickedCommitFgColor = [ base0D ];
              defaultFgColor = [ base05 ];
              optionsTextColor = [ base04 ];
              searchingActiveBorderColor = [ base0A ];
              selectedLineBgColor = [ base02 ];
              unstagedChangesColor = [ base08 ];
            };
          };

          keybinding = {
            universal = {
              jumpToBlock = [
                "0"
                "1"
                "2"
                "3"
                "4"
              ];
            };
          };
          promptToReturnFromSubprocess = false;
          os =
            let
              lazygitEdit = pkgs.writeShellApplication {
                name = "lazygit-edit";
                runtimeInputs = [ pkgs.coreutils ];
                text = ''
                  file=$(realpath -m -- "$1")
                  line=''${2:-0}

                  if [ -z "''${NVIM:-}" ]; then
                    if [ "$line" -gt 0 ]; then
                      exec nvim-focus "+$line" "$file"
                    fi
                    exec nvim-focus "$file"
                  fi

                  q="'"
                  esc=''${file//$q/$q$q}

                  nvim --server "$NVIM" --remote-send '<C-\><C-n><cmd>close<cr>'
                  nvim --server "$NVIM" --remote-expr "v:lua.LazygitEdit('$esc', $line)" >/dev/null
                '';
              };
            in
            {
              editInTerminal = true;
              edit = "${lazygitEdit}/bin/lazygit-edit {{filename}}";
              editAtLine = "${lazygitEdit}/bin/lazygit-edit {{filename}} {{line}}";
            };
          customCommands = [
            {
              key = "D";
              command = "git show {{.SelectedLocalCommit.Hash}} | diffnav";
              context = "commits";
              output = "terminal";
              description = "Open selected commit in diffnav";
            }
          ];
        };
      };
    };
  exo.skeleton =
    {
      pkgs,
      config,
      lib,
      wrapPackage,
      ...
    }:
    let
      cfg = config.forte.lazygit;
    in
    {
      config = lib.mkMerge [
        (lib.mkIf cfg.enable {
          hj.packages = [
            cfg.package
            pkgs.gh
            pkgs.diffnav
            pkgs.delta
          ];
          hj.environment.sessionVariables = {
            GIT_PAGER = "diffnav";
          };
          forte.persist.home.directories = [
            ".local/state/lazygit"
            ".config/gh"
          ];
          programs.fish.shellFunctions.lg.body = # fish
            ''
              set -x LAZYGIT_NEW_DIR_FILE ${config.hj.xdg.config.directory}/lazygit/newdir
              command ${lib.getExe cfg.package} $argv
              if test -f $LAZYGIT_NEW_DIR_FILE
                cd (cat $LAZYGIT_NEW_DIR_FILE)
                rm -f $LAZYGIT_NEW_DIR_FILE
              end
            '';
        })
        (lib.mkIf (cfg.enable && cfg.withWorktrunk) {
          hj.packages = [ cfg.worktrunkPackage ];
          programs.fish.interactiveShellInit = "${lib.getExe cfg.worktrunkPackage} config shell init fish | source ";
        })
      ];
      options.forte.lazygit = {
        enable = lib.mkEnableOption "lazygit";
        withWorktrunk = lib.mkEnableOption "worktrunk integration";
        settings = lib.mkOption {
          default = { };
          inherit (pkgs.formats.yaml { }) type;
        };
        package = lib.mkOption {
          type = lib.types.package;
          default = wrapPackage {
            package = pkgs.lazygit;
            files."configuration/lazygit.yml" = wrapPackage.yaml cfg.settings;
            env.LG_CONFIG_FILE = wrapPackage.out + "configuration/lazygit.yml";
          };
        };
        worktrunkPackage = lib.mkOption {
          type = lib.types.package;
          default = wrapPackage {
            package = pkgs.worktrunk;
            env.WORKTRUNK_CONFIG_PATH = wrapPackage.out + "/configuration/config.toml";
            files."configuration/config.toml" = wrapPackage.toml {
              skip-shell-integration-prompt = true;
              skip-commit-generation-prompt = true;
              merge = {
                squash = false;
                commit = false;
                rebase = true;
                remove = false;
                verify = true;
                ff = true;
              };
            };
          };
        };
      };
    };
}
