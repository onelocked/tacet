{
  exo.mods.media = { scheme, ... }: {
    forte.mpv-image = {
      enable = true;
      conf = # ini
        ''
          image-display-duration=inf
          loop-file=inf
          autofit=x1200
          osd-level=0
          window-dragging=no
          osc=no
          gpu-context=auto
          hwdec=auto-copy
          profile=gpu-hq
          vo=gpu-next
          gpu-api=auto
          background=color
          background-color="${scheme.base00}"
        '';
      input = # bash
        ''
          MBTN_LEFT script-binding positioning/drag-to-pan
          WHEEL_UP      add video-zoom  0.1
          WHEEL_DOWN    add video-zoom -0.1

          k             add video-pan-y  0.01
          j             add video-pan-y -0.01
          h             add video-pan-x  0.01
          l             add video-pan-x -0.01

          Ctrl+r         set video-zoom 0 ; set video-pan-x 0 ; set video-pan-y 0
        '';
    };

  };
  exo.skeleton =
    {
      lib,
      config,
      self',
      pkgs,
      wrapPackage,
      ...
    }:
    let
      cfg = config.forte.mpv-image;
    in
    {
      config = lib.mkIf cfg.enable {
        hj.packages = [ cfg.package ];
        forte.xdg.desktopEntries."mpvi" = {
          name = "MPV Image Viewer";
          exec = "${cfg.package}/bin/mpv %U";
          noDisplay = true;
          icon = "mpv";
          mimeType = [
            "image/png"
            "image/jpeg"
            "image/jpg"
            "image/webp"
            "image/gif"
          ];
        };
        xdg.mime.defaultApplications =
          [
            # Image
            "image/bmp"
            "image/gif"
            "image/jpeg"
            "image/jpg"
            "image/png"
            "image/tiff"
            "image/vnd.microsoft.icon"
            "image/webp"
          ]
          |> map (mime: lib.nameValuePair mime [ "mpvi.desktop" ])
          |> lib.listToAttrs;
      };
      options.forte.mpv-image = {
        enable = lib.mkEnableOption "mpv-image";
        conf = lib.mkOption {
          default = "";
          type = lib.types.lines;
        };

        input = lib.mkOption {
          type = lib.types.lines;
          default = "";
        };

        package = lib.mkOption {
          type = lib.types.package;
          default =
            let
              mpvScripts = pkgs.symlinkJoin {
                name = "mpv-scripts";
                paths = [ self'.legacyPackages.mpv-rotate-resize ];
              };
            in
            wrapPackage {
              package = pkgs.mpv;
              files.configuration = {
                "mpv.conf" = cfg.conf;
                "input.conf" = cfg.input;
                "scripts" = "${mpvScripts}/share/mpv/scripts";
                "script-opts/rotate-resize.conf" = "keybinds=r";
              };
              env.MPV_HOME = wrapPackage.out + "configuration";
            };
        };
      };
    };
}
