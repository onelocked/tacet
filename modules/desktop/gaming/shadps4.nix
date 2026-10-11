{
  exo.mods.shadps4 = { pkgs, ... }: {
    hj.packages = [ pkgs.shadps4-qtlauncher ];
    programs.steam.extraPackages = [ pkgs.shadps4-qtlauncher ];
    forte.persist.home.directories = [
      ".local/share/shadPS4"
      ".config/bbport-launcher"
    ];
  };
  tack.inputs.pkg-install = {
    url = "gh:Muggle345/PKGInstall";
    type = "fetch";
    frozen = true;
    submodules = true;
  };
  perSystem =
    { pkgs, inputs, ... }:
    {
      # To install PKG
      packages.pkg-install = pkgs.stdenv.mkDerivation (finalAttrs: {
        pname = "PKG-INSTALL";
        version = inputs._meta.pkg-install.rev;
        __structuredAttrs = true;
        strictDeps = true;

        src = inputs.pkg-install;

        doCheck = false;

        nativeBuildInputs = with pkgs; [
          cmake
          qt6.wrapQtAppsHook
        ];

        buildInputs = with pkgs; [
          qt6.qtbase
          qt6.qttools
          qt6.qtdeclarative
          qt6.qtmultimedia
          qt6.wrapQtAppsHook
          cryptopp
        ];

        postPatch = "cp -r dist/* . ";

        postInstall = "install -Dm755 PKGInstall $out/bin/PKGInstall ";

        meta = {
          description = "pkg install for shadps4";
          homepage = "https://github.com/Muggle345/PKGInstall";
        };
      });
    };
}
