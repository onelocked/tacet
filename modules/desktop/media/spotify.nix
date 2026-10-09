{
  tack.inputs.spicetify-nix = {
    url = "gh:Gerg-L/spicetify-nix";
    group = "desktop";
  };
  exo.mods.media =
    {
      inputs',
      inputs,
      scheme,
      config,
      lib,
      ...
    }:
    let
      spicePkgs = inputs'.spicetify-nix.legacyPackages;
      cfg = config.programs.spicetify;
    in
    {
      imports = [ inputs.spicetify-nix.nixosModules.default ];
      config = lib.mkMerge [
        {
          programs.spicetify = {
            enable = true;
            theme = spicePkgs.themes.text;
            customColorScheme = with scheme.noHashtag; {
              accent = base0E;
              accent-active = base0D;
              accent-inactive = base03;
              banner = base0D;
              border-active = base0F;
              border-inactive = base01;
              header = base04;
              highlight = base03;
              main = base00;
              notification = base16;
              notification-error = base08;
              subtext = base04;
              text = base05;
            };
            enabledExtensions = with spicePkgs.extensions; [
              adblock
              hidePodcasts
            ];
          };
        }
        (lib.mkIf cfg.enable {
          forte.allowUnfree = [ "spotify" ];
          hj.systemd.services = {
            spotify = {
              enableDefaultPath = false;
              description = "spotify autostart";
              after = [ "graphical-session.target" ];
              wantedBy = [ "graphical-session.target" ];
              serviceConfig = {
                Type = "simple";
                ExecStart = "${lib.getExe cfg.spicedSpotify}";
              };
            };
          };
          forte.hyprland.lua.window-rules =
            # lua
            ''
              hl.window_rule({
                name      = "spotify",
                match     = { class = "spotify" },
                workspace = "5 silent",
                scrolling_width = 0.5,
              })
            '';
          forte.persist.home.directories = [
            ".config/spotify"
            ".cache/spotify"
          ];
        })
      ];
    };
}
