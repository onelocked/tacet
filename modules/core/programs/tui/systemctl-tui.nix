{
  tack.inputs.systemctl-tui = {
    url = "gh:rgwood/systemctl-tui";
    type = "fetch";
    group = "general";
    patches = [
      "https://gist.githubusercontent.com/onelocked/e48437bfd359f572650840402de884c4/raw/d04b2e1d30eba53cfbf60bf31b5f8998899d6708/systemctl-square-borders.patch"
      "https://gist.githubusercontent.com/onelocked/856e61345d0507dec374b32ef68d12a8/raw/3f1b321bed38f60b82795d4017f7d2a7388c5494/systemctl-colors.patch"
    ];
  };
  exo.core =
    {
      self',
      wrapPackage,
      scheme,
      ...
    }:
    {
      hj.packages = [
        (wrapPackage {
          package = self'.packages.systemctl-tui;
          binName = "isd";
          files."configuration/config.toml" = wrapPackage.toml (
            with scheme;
            {
              accent = base0D;
              border = base03;
              selection = base02;
              primary = base0D;
            }
          );
          env.SYSTEMCTL_TUI_CONFIG = "${wrapPackage.out}/configuration/config.toml";
        })
      ];
    };
  perSystem =
    { inputs, pkgs, ... }:
    {
      remotePackages.systemctl-tui = pkgs.rustPlatform.buildRustPackage (finalAttrs: {
        pname = inputs._meta.systemctl-tui.repo;
        version = inputs._meta.systemctl-tui.rev;
        src = inputs.systemctl-tui;
        cargoLock.lockFile = finalAttrs.src + "/Cargo.lock";
        doCheck = false;
        cargoBuildFlags = [
          "--config"
          "profile.release.strip=true"
        ];
      });
    };
}
