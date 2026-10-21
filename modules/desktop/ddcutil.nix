{
  exo.mods.desktop = { pkgs, constants, ... }: {
    hardware.i2c.enable = true;
    hj.packages = [ pkgs.ddcutil ];
    users.users."${constants.username}".extraGroups = [ "i2c" ];
  };
}
