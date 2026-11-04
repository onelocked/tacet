{
  exo.mods.media =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      cfg = config.forte.ayugram;
    in
    {
      config = lib.mkIf cfg.enable {
        hj.packages = [ cfg.package ];
        forte.persist.home.directories = [ ".local/share/AyuGramDesktop" ];
        forte.hyprland.lua.window-rules = # lua
          ''
            hl.window_rule({
                name           = "Telegram",
                match          = { class = "com.ayugram.desktop", title = "negative:^Media viewer$" },
                fullscreen     = false,
                float          = true,
                size           = "700 1330",
                move           = "35 78",
                workspace      = "special:magic silent",
                suppress_event = "fullscreen maximize activate activatefocus",
            })
            hl.window_rule({
              name             = "Telegram-media",
              match            = { class = "com.ayugram.desktop", title = "^Media viewer$" },
              workspace        = "special:magic silent",
              fullscreen       = false,
              fullscreen_state = "0 1",
              float            = true,
              size             = { 1900, 1100 },
            })
          '';
      };
      options.forte.ayugram = {
        enable = lib.mkEnableOption "ayugram" // {
          default = true;
        };
        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.ayugram-desktop;
        };
      };
    };
}
