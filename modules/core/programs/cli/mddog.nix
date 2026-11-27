{
  tack.inputs.mddog = {
    url = "gh:qu8n/mddog";
    group = "cli";
    type = "fetch";
  };
  exo.core = { self', ... }: {
    hj.packages = [ self'.packages.mddog ];
  };
  perSystem = { pkgs, inputs, ... }: {
    remotePackages.mddog = pkgs.rustPlatform.buildRustPackage (finalAttrs: {
      pname = inputs._meta.mddog.repo;
      version = inputs._meta.mddog.rev;
      src = inputs.mddog;
      cargoLock.lockFile = finalAttrs.src + "/Cargo.lock";
      doCheck = false;
    });
  };
}
