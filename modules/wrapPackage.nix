{ lib, ... }:
let
  wrapperModule =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      config = {
        makeWrapperArgs =
          let
            renderEnv =
              value:
              if lib.isPath value then
                "${value}"
              else if lib.isString value then
                value
              else
                toString value;
          in
          lib.optionals (config.env != { }) (
            config.env
            |> lib.mapAttrsToList (
              name: value: [
                "--set"
                name
                (renderEnv value)
              ]
            )
            |> lib.concatLists
          )
          ++ lib.optionals (config.extraPkgs != [ ]) [
            "--prefix"
            "PATH"
            ":"
            (config.extraPkgs |> lib.makeBinPath)
          ]
          ++ lib.optionals (config.args != [ ]) (
            config.args
            |> lib.concatMap (value: [
              "--add-flag"
              value
            ])
          )
          ++ lib.optionals (config.runShell != [ ]) (
            config.runShell
            |> lib.concatMap (value: [
              "--run"
              value
            ])
          );
        wrapper =
          let
            inherit (config)
              package
              binName
              files
              makeWrapperArgs
              ;
            paths = lib.unique config.paths;
            aliases = lib.unique config.aliases;
            sourceBin = package.meta.mainProgram or (lib.getName package);
            flattenFiles =
              prefix: attrs:
              lib.concatLists (
                lib.mapAttrsToList (
                  name: value:
                  let
                    target = if prefix == "" then name else "${prefix}/${name}";
                  in
                  if lib.isAttrs value && !lib.isDerivation value then
                    flattenFiles target value
                  else
                    [
                      {
                        name = target;
                        inherit value;
                      }
                    ]
                ) attrs
              );
            inherit (flattenFiles "" files |> builtins.partition (file: lib.isString file.value))
              right
              wrong
              ;
            textFiles = right |> lib.imap0 (index: file: file // { key = "f${toString index}"; });
            linkFiles = wrong;
          in
          pkgs.runCommandLocal "${lib.getName package}-onewrap"
            (
              {
                nativeBuildInputs = with pkgs; [
                  makeWrapper
                  lndir
                ];
                meta = removeAttrs (package.meta or { }) [ "outputsToInstall" ] // {
                  mainProgram = binName;
                };
                passAsFile = textFiles |> map (file: file.key);
              }
              // (
                textFiles
                |> map (file: {
                  name = file.key;
                  value = file.value;
                })
                |> lib.listToAttrs
              )
            )
            (
              let
                wrapperArgs = lib.escapeShellArgs makeWrapperArgs;
              in
              #bash
              ''
                mkdir -p $out
                lndir -silent ${package} $out
                ${paths |> lib.concatMapStringsSep "\n" (pkgPath: "lndir -silent ${pkgPath} $out")}

                ${
                  linkFiles
                  |> lib.concatMapStringsSep "\n" (
                    file:
                    if lib.isList file.value then
                      #bash
                      ''
                        mkdir -p "$out/${file.name}"
                        ${lib.concatMapStringsSep "\n" (v: ''
                          if [ -d ${lib.escapeShellArg v} ]; then
                            lndir -silent ${lib.escapeShellArg v} "$out/${file.name}"
                          else
                            ln -sf ${lib.escapeShellArg v} "$out/${file.name}/"
                          fi
                        '') file.value}
                      ''
                    else
                      #bash
                      ''
                        mkdir -p "$(dirname "$out/${file.name}")"
                        ln -sf ${lib.escapeShellArg file.value} "$out/${file.name}"
                      ''
                  )
                }

                ${
                  textFiles
                  |> lib.concatMapStringsSep "\n" (
                    file: # bash
                    ''
                      install -Dm644 "''$${file.key}Path" "$out/${file.name}"
                    ''
                  )
                }

                if [ ! -e "$out/bin/${binName}" ]; then
                  makeWrapper ${lib.getExe' package sourceBin} "$out/bin/${binName}" ${wrapperArgs}
                else
                  wrapProgram "$out/bin/${binName}" ${wrapperArgs}
                fi
                ${
                  aliases
                  |> lib.concatMapStringsSep "\n" (
                    alias: "ln -sf \"$out/bin/${binName}\" \"$out/bin/\"${lib.escapeShellArg alias}"
                  )
                }
              ''
            );
      };
      options = {
        package = lib.mkOption {
          type = lib.types.package;
          description = "The main package to wrap.";
          example = lib.literalExpression "pkgs.foot";
        };

        paths = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [ ];
          description = ''
            Additional packages to symlink into the output directory.
            Earlier entries win on file collisions; the main package always wins.
          '';
        };

        binName = lib.mkOption {
          type = lib.types.str;
          default = config.package.meta.mainProgram or (lib.getName config.package);
          defaultText = lib.literalExpression "config.package.meta.mainProgram or (lib.getName config.package)";
          description = "Name of the wrapped binary at $out/bin/<binName>.";
        };

        args = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = ''
            Additional command-line arguments. Each element is passed as a
            single argument (makeWrapper's `--add-flag`).
          '';
          example = lib.literalExpression ''[ "--config" "/etc/foo.conf" ]'';
        };

        env = lib.mkOption {
          type =
            with lib.types;
            attrsOf (oneOf [
              str
              path
              int
            ]);
          default = { };
          description = ''
            Environment variables set by the wrapper (via `--set`).
            Path values are copied into the store.
          '';
          example = {
            LC_ALL = "C.UTF-8";
            FOO_CONFIG = "/etc/foo.conf";
          };
        };

        extraPkgs = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [ ];
          description = "Packages prepended to PATH at runtime.";
        };

        files = lib.mkOption {
          type =
            let
              leaf =
                with lib.types;
                either
                  (listOf (oneOf [
                    str
                    path
                    package
                  ]))
                  (oneOf [
                    str
                    path
                    package
                  ]);
              tree = lib.types.either leaf (lib.types.attrsOf tree);
            in
            lib.types.attrsOf tree;
          default = { };
          description = ''
            Files to add to the wrapper output. String values are written
            verbatim; use a path, a package, or a single-element list to
            symlink something instead. Lists are treated as link sources and
            merged with `lndir` (directories) or symlinked (files). Attribute
            sets are treated as nested directories.
          '';
          example = lib.literalExpression ''
            {
              "configuration/foo.toml" = "key = 1";
              "share/thing" = pkgs.somePackage;
            }
          '';
        };

        aliases = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Additional names for the wrapped binary in $out/bin.";
        };

        runShell = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Commands to run before executing the main program. They run after `env` and `extraPkgs` have been applied.";
        };

        makeWrapperArgs = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Raw arguments passed to makeWrapper/wrapProgram after the arguments generated from the other options.";
        };

        wrapper = lib.mkOption {
          type = lib.types.package;
          readOnly = true;
          description = "The built, wrapped derivation.";
        };
      };
    };

  wrap =
    pkgs: spec:
    let
      evaluated = lib.evalModules {
        modules = [
          wrapperModule
          spec
        ];
        specialArgs = { inherit pkgs; };
      };
    in
    evaluated.config.wrapper.overrideAttrs (old: {
      passthru = (old.passthru or { }) // {
        inherit (evaluated.config) package;
        unwrapped = evaluated.config.package;
        override = newSpec: wrap pkgs (spec // newSpec);
      };
    });

  wrapFunctor = pkgs: {
    inherit pkgs;
    __functor = self: spec: wrap pkgs spec;
    out = placeholder "out";
    toml = (pkgs.formats.toml { }).generate "config.toml";
    json = (pkgs.formats.json { }).generate "config.json";
    yaml = (pkgs.formats.yaml { }).generate "config.yaml";
    ini = (pkgs.formats.ini { }).generate "config.ini";
  };
in
{
  exo.core =
    { pkgs, ... }:
    {
      _module.args.wrapPackage = wrapFunctor pkgs;
    };
  perSystem =
    { pkgs, ... }:
    {
      _module.args.wrapPackage = wrapFunctor pkgs;
    };
}
