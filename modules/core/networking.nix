{
  exo.core =
    { lib, server, ... }:
    {
      networking = {
        firewall.enable = true;
        networkmanager.enable = true;
      };

      forte.persist.root.directories = [ "/var/lib/NetworkManager" ];

      services.resolved.enable = true;

      services.avahi = lib.mkIf (!server) {
        enable = true;
        settings = {
          publish."disable-publishing" = false;
        };
        openFirewall = true;
        nssmdns4 = true;
      };

      # TCP fq optimisation
      boot = {
        kernelModules = [ "tcp_bbr" ];
        kernel.sysctl = {
          "net.ipv4.tcp_congestion_control" = "bbr";
          "net.core.default_qdisc" = "cake";
        };
      };
    };
}
