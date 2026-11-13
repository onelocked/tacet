{
  exo.core =
    { scheme, self', ... }:
    {
      forte.lazygit = {
        enable = true;
        withWorktrunk = true;
        settings = with scheme; {
          git = {
            autoFetch = false;
            overrideGpg = true;
            diffRenderers = [
              {
                colorArg = "always";
                command = "hunk pager";
              }
              {
                colorArg = "always";
                command = "hunk pager --mode=split";
              }
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
            sidePanels = [
              [
                "files"
                "worktrees"
                "submodules"
              ]
              [
                "branches"
                "remotes"
                "tags"
              ]
              [
                "commits"
                "reflog"
                "stash"
              ]
            ];
            theme = {
              authorColors = {
                "*" = base16;
              };
              activeBorderColor = [ base0D ];
              inactiveBorderColor = [ base03 ];
              cherryPickedCommitBgColor = [ base02 ];
              cherryPickedCommitFgColor = [ base0D ];
              defaultFgColor = [ base05 ];
              optionsTextColor = [ base04 ];
              searchingActiveBorderColor = [ base0A ];
              selectedLineBgColor = [ base02 ];
              selectedLineFgColor = [
                "bold"
              ];
              unstagedChangesColor = [ base08 ];
            };
          };

          keybinding.universal = {
            jumpToBlock = [
              "1"
              "2"
              "3"
            ];
            focusMainView = "4";
          };
          promptToReturnFromSubprocess = false;
          customCommands = [
            {
              key = "E";
              command = "${self'.legacyPackages.diffWorktree}/bin/diffWorktree {{.SelectedLocalCommit.Hash}}";
              context = "commits";
              output = "none";
              description = "Open commit diff in diffview (edits become unstaged)";
            }
            {
              key = "E";
              command = "${self'.legacyPackages.diffWorktree}/bin/diffWorktree {{.SelectedCommit.Sha}} '{{.SelectedCommitFile.Name}}'";
              context = "commitFiles";
              output = "none";
              description = "Open file diff in diffview (edits become unstaged)";
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
            pkgs.hunk
            pkgs.delta
          ];
          hj.environment.sessionVariables = {
            GIT_PAGER = "hunk pager";
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
            env.LG_CONFIG_FILE = "${wrapPackage.out}/configuration/lazygit.yml";
          };
        };
        worktrunkPackage = lib.mkOption {
          type = lib.types.package;
          default = wrapPackage {
            package = pkgs.worktrunk;
            env.WORKTRUNK_CONFIG_PATH = "${wrapPackage.out}/configuration/config.toml";
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
  perSystem = { pkgs, ... }: {
    legacyPackages.diffWorktree =
      pkgs.writeShellScriptBin "diffWorktree" # bash
        ''
          set -euo pipefail

          case "''${1:-}" in
            apply)
              git -C "$LG_WT" add -A --sparse -- . >/dev/null 2>&1 || true
              patch=$(mktemp)
              git -C "$LG_WT" diff --binary HEAD > "$patch"
              if [[ -s "$patch" ]] && git -C "$LG_REPO" apply "$patch"; then
                git -C "$LG_WT" -c user.name=lazygit -c user.email=lazygit@localhost \
                  -c commit.gpgsign=false commit --no-verify -q -m "lazygit save"
              fi
              rm -f "$patch"
              exit 0
              ;;
            cleanup)
              cd /
              git -C "$LG_REPO" worktree remove --force "$LG_WT" >/dev/null 2>&1 || true
              exit 0
              ;;
          esac

          commit=$1
          file=''${2:-}
          repo=$(git rev-parse --show-toplevel)
          short=$(git rev-parse --short "$commit")

          if git rev-parse --verify --quiet "$commit^1" >/dev/null; then
            base=$(git rev-parse "$commit^1")
          else
            base=$(git hash-object -t tree /dev/null)
          fi

          runtime_dir="''${TMPDIR:-/tmp}"
          mkdir -p "$runtime_dir/lazygit-diff"
          wt=$(mktemp -d "$runtime_dir/lazygit-diff/$short.XXXXXX")
          git -C "$repo" worktree add --detach --no-checkout "$wt" "$commit" >/dev/null 2>&1

          if [[ -n "$file" ]]; then
            paths=("$file")
          else
            mapfile -d $'\x00' -t paths < <(git -C "$repo" diff --name-only -z "$base" "$commit")
          fi
          patterns=()
          for path in "''${paths[@]}"; do
            path=''${path//\\/\\\\}
            path=''${path//\*/\\*}
            path=''${path//\?/\\?}
            path=''${path//\[/\\[}
            path=''${path//\]/\\]}
            patterns+=("/$path")
          done
          if (( ''${#patterns[@]} > 0 )); then
            git -C "$wt" sparse-checkout set --no-cone -- "''${patterns[@]}"
          else
            git -C "$wt" sparse-checkout set --no-cone -- "/.lazygit-no-files"
          fi
          git -C "$wt" read-tree -mu HEAD

          exec kitty -1 \
            --app-id=diff-nvim --directory "$wt" \
            env LG_REPO="$repo" LG_WT="$wt" LG_COMMIT="$commit" LAZYGIT_DIFF_PATH="$file" \
            nvim -c "execute 'DiffviewOpen $base' . (empty(\$LAZYGIT_DIFF_PATH) ? \"\" : ' -- ' . fnameescape(\$LAZYGIT_DIFF_PATH))" \
            -c "autocmd BufWritePost * call system('$0 apply')" \
            -c "autocmd VimLeavePre * call system('$0 cleanup')" \
            -c 'autocmd User DiffviewViewClosed qa'
        '';
  };
}
