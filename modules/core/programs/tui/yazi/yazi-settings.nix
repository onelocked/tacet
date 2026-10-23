{
  exo.core = {
    forte.yazi = {
      enable = true;
      settings = {
        tasks = {
          bizarre_retry = 3;
          image_alloc = 536870912;
          image_bound = [
            0
            0
          ];
          suppress_preload = true;
        };
        mgr = {
          sort_by = "natural";
          sort_sensitive = false;
          show_hidden = false;
          show_symlink = true;
          sort_reverse = false;
          sort_dir_first = true;
          linemode = "size";
          sort_translit = false;
          scrolloff = 5;
          title_format = "Yazi: {cwd}";
          ratio = [
            1
            2
            4
          ];
        };
        preview = {
          wrap = "no";
          tab_size = 2;
          image_filter = "triangle"; # from fast to slow but high quality: nearest, triangle, catmull-rom, lanczos3
          cache_dir = "";
          image_delay = 0;
          max_width = 1920;
          max_height = 1344;
          image_quality = 60;
          sixel_fraction = 15;
        };
      };
      keymap = {
        mgr.prepend_keymap =
          let
            mkKeymap = on: run: desc: { inherit on run desc; };
          in
          [
            (mkKeymap [ "g" "r" ] ''shell -- ya emit cd "$(git rev-parse --show-toplevel)"'' "git root")
            (mkKeymap [ "g" "s" ] "shell -- ya emit cd /mnt/s3" "Go to S3")
            (mkKeymap [ "i" "m" ] "shell -- nix run nixpkgs#yt-dlp $(wl-paste)" "Download video")
          ];
      };
    };
  };
}
