{
  tack.inputs.mddog = {
    url = "gh:qu8n/mddog/issue-20-add-linux-support";
    group = "cli";
    type = "fetch";
    frozen = true;
    patches = [
      "https://gist.githubusercontent.com/onelocked/10889b2ce08bd001867958980ef05679/raw/b13c78ccbb9e69a402ae7f89fbb7b35bfeba9ff4/mddog-mardown-fix.patch"
    ];
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
