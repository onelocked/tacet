{ inputs, ... }:
{
  tack.inputs = {
    spot = {
      url = "gh:AminurAlam/yazi-plugins";
      type = "fetch";
      group = "sxyazi";
    };
  };
  exo.core =
    { pkgs, lib, ... }:
    {
      forte.yazi = {
        plugins =
          [
            "spot"
            "spot-image"
            "spot-video"
            "spot-audio"
          ]
          |> map (
            name:
            lib.nameValuePair name (
              pkgs.yaziPlugins.mkYaziPlugin {
                pname = name;
                version = "1.0";
                src = pkgs.lib.cleanSourceWith {
                  src = "${inputs.spot}/${name}.yazi";
                  filter = path: _type: baseNameOf path == "main.lua";
                };
              }
            )
          )
          |> lib.listToAttrs;

        settings.plugins = {
          prepend_spotters =
            let
              byMime = mime: run: { inherit mime run; };
              byUrl = url: run: { inherit url run; };
            in
            [
              (byMime "audio/*" "spot")
              (byMime "image/*" "spot-image")
              (byUrl "video/*" "spot-video")
              (byMime "audio/mpegurl" "code")
              (byUrl "audio/*" "spot-audio")
              (byUrl "*/" "spot")
              (byUrl "*" "spot")
            ];
        };

        initLua = # lua
          ''
            require('spot'):setup {
              metadata_section = {
                enable = true,
                hash_cmd = 'xxhsum',
                hash_filesize_limit = 150,
                relative_time = true,
                time_format = '%Y-%m-%d %H:%M',
                show_compression = true,
              },
              plugins_section = {
                enable = false,
              },
              style = {
                section = 'green',
                key = 'reset',
                value = 'blue',
                selected = 'blue',
                colorize_metadata = true,
                height = 20,
                width = 60,
                key_length = 15,
              },
            }
          '';
      };
    };
}
