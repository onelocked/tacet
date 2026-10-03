{
  rootPath,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkOption types;
in
{
  config = {
    tack = {
      inputs.tack = {
        url = "gh:manic-systems/tack";
        group = "nix";
      };
      shorturls = {
        gh = "github:{path}";
      };
      tack.recomposable = true;
      all_follow = {
        nixpkgs = "nixpkgs";
        systems = "systems";
        flake-compat = "flake-compat";
        flake-utils = "flake-utils";
        rust-overlay = "rust-overlay";
        treefmt-nix = "treefmt-nix";
        tack = "tack";
      };
      omit_inputs.names = [
        "flake-compat"
        "pre-commit-hooks"
        "treefmt-nix"
      ];
    };

    perSystem =
      {
        packages',
        self',
        pkgs,
        ...
      }:
      {
        packages = { inherit (packages') tack; };

        apps.tack-rebuild = {
          type = "app";
          meta.description = "A flake-file like, pins.toml updater for tack";
          program = lib.getExe (
            pkgs.writeShellApplication {
              name = "write-tack";

              derivationArgs = {
                allowSubstitutes = false;
                preferLocalBuild = true;
              };

              runtimeInputs = [
                self'.packages.tack
                pkgs.delta
                pkgs.nh
              ];

              text =
                let
                  cfg = config.tack |> lib.filterAttrsRecursive (_: value: !isNull value);
                  nameValuePairToToml = # This represents a simple Nix -> TOML name-value pair
                    name: value: "${lib.strings.escapeNixIdentifier name} = ${mapValueToTomlRhs value}";
                  mapAttrSetToToml = sep: lib.concatMapAttrsStringSep sep nameValuePairToToml;
                  mapValueToTomlRhs = v: if lib.isAttrs v then "{ ${mapAttrSetToToml ", " v} }" else lib.toJSON v;
                  # Tack options section
                  tackOptsToml =
                    cfg
                    |> lib.flip lib.removeAttrs [ "inputs" ]
                    |> lib.concatMapAttrsStringSep "" (
                      name: value: ''
                        [${name}]
                        ${value |> mapAttrSetToToml "\n"}

                      ''
                    );
                  # Tack inputs section
                  tackInputsToml =
                    cfg.inputs
                    |> lib.concatMapAttrsStringSep "\n" (
                      name: value: ''
                        [inputs.${name}]
                        ${value |> mapAttrSetToToml "\n"}
                      ''
                    );
                  # The contents of pins.toml generated via nix
                  tackTomlString = "${tackOptsToml}${tackInputsToml}";
                  oldTackTomlString = lib.readFile (rootPath + /.tack/pins.toml);
                  oldTackToml = lib.fromTOML oldTackTomlString;
                  oldInputs = oldTackToml.inputs;
                  newInputs = cfg.inputs;
                  oldKeys = lib.attrNames oldInputs;
                  newKeys = lib.attrNames newInputs;
                  # Inputs that exist in new but not in old
                  newInputNames = newKeys |> lib.subtractLists oldKeys;

                  # Input-level options that _if changed_ should not trigger a `tack update`
                  normalizeInput = lib.flip lib.removeAttrs [
                    "group"
                    "frozen"
                    "patches"
                  ];

                  # Inputs that exist in both but have changed enough to need a `tack update`
                  changedInputNames =
                    (lib.intersectLists oldKeys newKeys)
                    |> lib.filter (name: normalizeInput oldInputs.${name} != normalizeInput newInputs.${name});

                  updatedInputs = newInputNames ++ changedInputNames;
                  removedInputs = oldKeys |> lib.subtractLists newKeys;

                  prevPatches = name: oldInputs.${name}.patches or [ ];
                  currPatches = name: newInputs.${name}.patches or [ ];

                  rmPatchCommands =
                    newKeys
                    |> lib.concatMap (
                      name:
                      lib.subtractLists (currPatches name) (prevPatches name)
                      |> map (patch: "tack patch rm ${lib.escapeShellArg name} ${lib.escapeShellArg patch}")
                    )
                    |> lib.concatLines;

                  addPatchCommands =
                    let
                      updatedPatchInputs =
                        newKeys
                        |> lib.filter (name: lib.subtractLists (prevPatches name) (currPatches name) != [ ])
                        |> lib.join " ";
                    in
                    "tack patch update ${updatedPatchInputs}";
                in
                # bash
                ''
                  PINS_FILE="''${TACK_DIR:-.tack}/pins.toml"

                  if [[ ! -f "$PINS_FILE" ]]; then
                    echo "Error: file not found: $PINS_FILE" >&2
                    exit 1
                  fi

                  TMP_PINS="$(mktemp -t old_pins.toml.XXXXX)"
                  # Delete temp file on script exit
                  trap 'rm -f "$TMP_PINS"' EXIT

                  ${rmPatchCommands}

                  ${removedInputs |> map (removedInput: "tack rm ${removedInput}") |> lib.concatLines}

                  ${lib.optionalString (cfg != oldTackToml) /* bash */ ''
                    mv "$PINS_FILE" "$TMP_PINS"
                    cat << 'EOF' > "$PINS_FILE"
                    ${tackTomlString}
                    EOF
                  ''}

                  ${lib.optionalString (updatedInputs != [ ]) "tack update ${lib.join " " updatedInputs}"}

                  ${addPatchCommands}

                  ${lib.optionalString (cfg != oldTackToml) # bash
                    ''delta --dark --paging=never --diff-highlight "$TMP_PINS" "$PINS_FILE" || true''
                  }

                  if [[ $# -gt 0 ]]; then
                    nh os "$@"
                  fi
                '';
            }
          );
        };
      };

    exo.core =
      { packages', ... }:
      {
        hj.packages = [ packages'.tack ];
        hj.environment.sessionVariables = {
          TACK_NIX_CONF_TOKENS = "1";
        };
        forte.persist.home.directories = [ ".cache/nix" ];
      };
  };
  options.tack = {
    shorturls = mkOption {
      type = types.nullOr (types.attrsOf types.str);
      description = ''
        Shorturl schemes. `scheme:rest` expands by substituting `rest` into
        the `{path}` placeholder of the template.
      '';
      example = {
        gh = "github:{path}";
      };
    };

    all_follow = mkOption {
      type = types.nullOr (types.attrsOf (types.either types.str (types.listOf types.str)));
      description = ''
        Follow rules applied to every pin that has a matching input. Two value
        shapes are accepted:

        - `alias = "target"`: every input named `alias` follows your top-level `target` pin.
        - `target = [ "alias1" "alias2" ]`: the key is the canonical target, and the
          key plus every array member alias to it.
      '';
      example = {
        nixpkgs = [
          "nixpkgs-stable"
          "nixpkgs-unstable"
        ];
        fenix = "fenix";
      };
    };

    tack = mkOption {
      type = types.nullOr (
        types.submodule {
          options = {
            recomposable = mkOption {
              type = types.nullOr types.bool;
            };
          };
        }
      );
    };

    omit_inputs = mkOption {
      type = types.nullOr (
        types.submodule {
          options = {
            names = mkOption {
              type = types.nullOr (types.listOf types.str);
            };
          };
        }
      );
    };

    inputs = mkOption {
      default = { };
      type = types.attrsOf (
        types.submodule {
          options = {
            url = mkOption {
              type = types.str;
              description = "Input URL. May use one of the configured shorturl schemes.";
              example = "gh:owner/repo";
            };

            type = mkOption {
              type = types.nullOr (
                types.enum [
                  "fetch"
                  "fixed"
                  "flake"
                ]
              );
              description = ''
                Pin type. `flake` (tack's default when unset) evaluates the input's
                flake.nix; `fetch` exposes only the source tree; `fixed` is a
                hash-locked download that `tack update` will refuse to silently relock.
              '';
            };

            unpack = mkOption {
              type = types.nullOr (
                types.enum [
                  "tarball"
                  "file"
                ]
              );
              description = ''
                Only for `type = "fixed"`. Auto-detected from the URL when unset.
              '';
            };

            group = mkOption {
              type = types.nullOr types.str;
              description = ''
                Tag pins with a group to print them under headers in tack look and tack update.
              '';
            };

            frozen = mkOption {
              type = types.nullOr types.bool;
              description = ''
                A frozen pin stays at its locked rev through tack update, and only moves when named directly.
              '';
            };

            patches = mkOption {
              type = types.nullOr (types.listOf types.str);
              description = "Patches to apply to the input, in order, with no import-from-derivation.";
              example = [
                "https://github.com/NixOS/nixpkgs/pull/444444"
                "patches/nixpkgs/local-fix.patch"
              ];
            };

            submodules = mkOption {
              type = types.nullOr types.bool;
              description = ''
                Recursively fetch git submodules, disabled by default.
              '';
            };

            follows = mkOption {
              type = types.nullOr (types.attrsOf types.str);
              description = ''
                Point this pin's inputs at your top-level pins instead of their own lock.
                Keys may be prefixed with `flake:` or `tack:` to target only one side
                when an upstream has both a flake input and a tack pin of that name.
              '';
              example = {
                nixpkgs = "nixpkgs";
                "flake:systems" = "systems";
              };
            };

            exclude_follow = mkOption {
              type = types.nullOr (types.listOf types.str);
              description = "Names of `all_follow` rules that should not apply to this pin.";
            };
          };
        }
      );
    };
  };
}
