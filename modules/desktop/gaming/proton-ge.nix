{
  tack.inputs.proton-ge = {
    url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/{tag}/{tag}-x86_64.tar.gz";
    type = "fixed";
    unpack = "tarball";
    tag = "GE-Proton{version}";
  };
  perSystem = { inputs, pkgs, ... }: {
    packages.proton-ge = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
      pname = "Proton-GE";
      version = inputs._meta.proton-ge.version;

      src = inputs.proton-ge;

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
          --replace-fail "${inputs._meta.proton-ge.tag}-x86_64" "Proton-GE-NIX"
      '';
    });
  };
}
