{
  tack.inputs.proton-cachyos = {
    url = "https://github.com/CachyOS/proton-cachyos/releases/download/{tag}/proton-cachyos-{version}-slr-x86_64_v3.tar.xz";
    type = "fixed";
    unpack = "tarball";
    tag = "cachyos-{version}-slr";
    group = "gaming";
  };
  perSystem = { inputs, pkgs, ... }: {
    packages.proton-cachyos = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
      pname = "Proton-CachyOS";
      version = inputs._meta.proton-cachyos.version;

      src = inputs.proton-cachyos;

      dontUnpack = true;
      dontConfigure = true;
      dontBuild = true;

      outputs = [
        "out"
        "steamcompattool"
      ];

      installPhase = ''
        # Make it impossible to add to an environment. You should use the appropriate NixOS option.
        # Also leave some breadcrumbs in the file.
        echo "${finalAttrs.pname} should not be installed into environments. Please use programs.steam.extraCompatPackages instead." > $out

        mkdir $steamcompattool
        ln -s $src/* $steamcompattool
        rm $steamcompattool/compatibilitytool.vdf
        cp $src/compatibilitytool.vdf $steamcompattool
      '';

      preFixup = ''
        substituteInPlace "$steamcompattool/compatibilitytool.vdf" \
          --replace-fail "proton-${inputs._meta.proton-cachyos.tag}-x86_64_v3" "Proton-CachyOS-NIX"
      '';
    });
  };
}
