{
  exo.mods.desktop = {
    forte.cliphist = {
      enable = true;
      systemd.startup = true;
    };
  };
  exo.skeleton =
    {
      pkgs,
      lib,
      self',
      config,
      ...
    }:
    let
      cfg = config.forte.cliphist;
    in
    {
      options.forte.cliphist = {
        enable = lib.mkEnableOption "cliphist";
        package = lib.mkOption {
          default = self'.packages.cliphist;
        };
        systemd.startup = lib.mkEnableOption "cliphist-systemd-startup";
      };
      config =
        lib.mkIf cfg.enable
        <| lib.mkMerge [
          {
            hj.packages = [ cfg.package ];
            forte.persist.home.directories = [ ".cache/cliphist" ];
          }
          (lib.mkIf cfg.systemd.startup {
            hj.systemd.services = {
              cliphist-text = {
                description = "Clipboard history service (Text)";
                after = [ "graphical-session.target" ];
                partOf = [ "graphical-session.target" ];
                wantedBy = [ "graphical-session.target" ];

                serviceConfig = {
                  ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${self'.packages.cliphist}/bin/cliphist store";
                  Restart = "on-failure";
                };
              };

              cliphist-image = {
                description = "Clipboard history service (Images)";
                after = [ "graphical-session.target" ];
                partOf = [ "graphical-session.target" ];
                wantedBy = [ "graphical-session.target" ];

                serviceConfig = {
                  ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --type image --watch ${self'.packages.cliphist}/bin/cliphist store";
                  Restart = "on-failure";
                };
              };
            };
          })
        ];
    };
  tack.inputs = {
    cliphist = {
      url = "gh:sentriz/cliphist";
      type = "fetch";
      group = "general";
    };
  };
  perSystem =
    {
      wrapPackage,
      inputs,
      pkgs,
      ...
    }:
    {
      remotePackages.cliphist = wrapPackage {
        env.CLIPHIST_MAX_STORE_SIZE = "1GB";
        package = pkgs.buildGoModule (finalAttrs: {
          pname = inputs._meta.cliphist.repo;
          version = inputs._meta.cliphist.rev;
          src = inputs.cliphist;
          doCheck = false;
          vendorHash = "sha256-fDl+ul1t2Ux1w5WcCo6YMJtrcC20o+eUEO3NNycSNvI=";
          patches = [
            (pkgs.writeText "fix-browser-copy-with-meta.patch" # go
              ''
                diff --git a/cliphist.go b/cliphist.go
                index 8e1eb95..375f807 100644
                --- a/cliphist.go
                +++ b/cliphist.go
                @@ -127,7 +127,7 @@ func store(dbPath string, in io.Reader, maxDedupeSearch, maxItems uint64, minLen
                 	}
                 	defer db.Close()

                -	if len(bytes.TrimSpace(input)) == 0 {
                +	if len(bytes.TrimSpace(input)) == 0 || isBrowserImageFallback(input) {
                 		return nil
                 	}
                 	tx, err := db.Begin(true)
                @@ -564,3 +564,13 @@ func parseSize(s string) (uint64, error) {
                 	}
                 	return num, nil
                 }
                +
                +func isBrowserImageFallback(input []byte) bool {
                +	s := string(input)
                +	const meta = "<meta http-equiv=\"content-type\" content=\"text/html; charset=utf-8\">"
                +	if !strings.HasPrefix(s, meta) {
                +		return false
                +	}
                +	rest := strings.TrimSpace(s[len(meta):])
                +	return strings.HasPrefix(rest, "<img") && strings.HasSuffix(rest, ">")
                +}
                --
                2.53.0
              ''
            )
          ];
        });
      };
    };
}
