{
  tack.inputs.helium-browser = {
    url = "gh:amaanq/helium-flake";
    group = "browser";
  };

  exo.mods.desktop = {
    forte.helium-browser = {
      enable = true;
      setAsDefaultBrowser = true;
    };
  };
  exo.skeleton =
    {
      lib,
      packages',
      config,
      ...
    }:
    let
      cfg = config.forte.helium-browser;
      mimeType = [
        "application/x-extension-shtml"
        "application/x-extension-xhtml"
        "application/x-extension-html"
        "application/x-extension-xht"
        "application/x-extension-htm"
        "x-scheme-handler/unknown"
        "x-scheme-handler/https"
        "x-scheme-handler/http"
        "application/xhtml+xml"
        "application/json"
        "application/pdf"
        "text/html"
      ];
    in
    {
      config = lib.mkIf cfg.enable {
        hj.packages = [ cfg.package ];
        forte.persist.home.directories = [
          ".config/net.imput.helium"
          ".cache/net.imput.helium"
        ];
        forte.hyprland.lua = {
          window-rules = # lua
            ''
              hl.window_rule({
                name             = "helium",
                match            = { class = "helium" },
                fullscreen_state = "0 1",
                scrolling_width  = 0.333,
              })
              hl.window_rule({
                name         = "helium_idle_inhibit",
                match        = {
                  class = "helium",
                  title = ".*(YouTube|TikTok).*",
                },
                idle_inhibit = "focus",
              })
              hl.window_rule({
                name             = "helium-pip",
                match            = { title = "Picture-in-picture" },
                float      = true,
                pin        = true,
                decorate = false,
                size       = { 711, 400 },
                move       = { 0,1040 },
                no_initial_focus = true,
                opacity          = "1 override",
              })
            '';
          keybinds = # lua
            ''
              hl.bind("SUPER + B", function()
                  local win = hl.get_window("class:helium")
                  if win then
                      hl.dispatch(hl.dsp.exec_raw("helium --new-window"))
                  else
                      hl.dispatch(hl.dsp.exec_cmd("helium", { workspace = 1 }))
                  end
              end)
            '';
        };
        forte.xdg.desktopEntries = {
          "helium" = {
            name = "Helium";
            exec = "helium --new-window %U";
            terminal = false;
            type = "Application";
            icon = "helium";
            inherit mimeType;
          };
          "excalidraw" = {
            name = "Excalidraw";
            genericName = "Visual Whiteboard";
            comment = "Start excalidraw";
            exec = "helium --app=https://excalidraw.onelock.org";
            type = "Application";
            icon = "excalidraw";
            startupNotify = false;
          };
        };
        xdg.mime = lib.mkIf cfg.setAsDefaultBrowser {
          defaultApplications =
            mimeType |> map (mime: lib.nameValuePair mime [ "helium.desktop" ]) |> lib.listToAttrs;
        };
      };
      options.forte.helium-browser = {
        enable = lib.mkEnableOption "helium-browser";
        package = lib.mkOption {
          type = lib.types.package;
          default = packages'.helium-browser;
        };
        setAsDefaultBrowser = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Set Zen Browser as default browser.";
        };
      };
    };
}
