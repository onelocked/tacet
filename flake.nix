{
  outputs =
    { self, ... }:
    let
      inputs = import ./.tack;
      inherit (inputs.nixpkgs) lib;

      rootPath = ./.;

      systemOutputKeys = [
        "packages"
        "legacyPackages"
        "devShells"
        "checks"
        "apps"
        "formatter"
      ];

      projectInput =
        system: input:
        systemOutputKeys
        |> lib.filter (key: input ? ${key} && input.${key} ? ${system})
        |> (keys: lib.genAttrs keys (key: input.${key}.${system}));

      withSystem =
        system: f:
        let
          pkgs = inputs.nixpkgs.legacyPackages.${system};
          inputs' = inputs |> lib.mapAttrs (_: projectInput system);
          self' = projectInput system self;
          packages' =
            inputs'
            |> lib.mapAttrs (
              name: key: (key.packages or { }) // (key.packages.default or key.packages.${name} or { })
            );
        in
        f {
          inherit
            system
            inputs
            rootPath
            pkgs
            inputs'
            self'
            packages'
            ;
        };

      #  Evaluate the top-level modules
      topEval = lib.evalModules {
        specialArgs = { inherit inputs withSystem rootPath; };
        modules =
          [
            ./modules
            ./hosts
            ./.secrets
          ]
          |> map (lib.fileset.fileFilter (file: file.hasExt "nix" && !lib.hasPrefix "_" file.name))
          |> lib.fileset.unions
          |> lib.fileset.toList;
      };

      # Evaluate perSystem blocks for each system
      systemOutputs = lib.genAttrs topEval.config.systems (
        system:
        withSystem system (
          specialArgs:
          (lib.evalModules {
            inherit specialArgs;
            modules = [
              topEval.config.perSystem
              { config._module.freeformType = lib.types.lazyAttrsOf lib.types.unspecified; }
            ];
          }).config
        )
      );

      # Transpose system-dependent configurations to the top level
      transposed = lib.genAttrs systemOutputKeys (
        key: lib.genAttrs (lib.attrNames systemOutputs) (system: systemOutputs.${system}.${key} or { })
      );
    in
    topEval.config.flake // transposed;
}
