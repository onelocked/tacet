{
  tack.inputs.nix-cachyos-kernel = {
    url = "gh:xddxdd/nix-cachyos-kernel";
    exclude_follow = [ "nixpkgs" ];
    group = "gaming";
    frozen = true;
  };
  exo.mods.cachyos-kernel =
    { inputs', lib, ... }:
    {
      boot.kernelPackages = lib.mkForce inputs'.nix-cachyos-kernel.legacyPackages.linuxPackages-cachyos-bore-lto-x86_64-v3;
    };
  exo.core = {
    nix.settings = {
      substituters = [ "https://attic.xuyh0120.win/lantian" ];
      trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];
    };
  };
}
