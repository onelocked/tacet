{
  tack.inputs = {
    scroll-overview = {
      url = "gh:yayuuu/hyprland-scroll-overview/new-release";
      patches = [
        "https://github.com/yayuuu/hyprland-scroll-overview/pull/78"
        "https://gist.githubusercontent.com/onelocked/45255ba95ff9d552a86751f1ea6ae733/raw/8d833b2f9b039d19eed5f12b82aa70697553773f/scrollview.patch"
      ];
      type = "fetch";
      group = "hypr";
    };
  };

  exo.mods.desktop =
    { self', ... }:
    {
      forte.hyprland.plugins = [ self'.legacyPackages.scrolloverview ];
      forte.hyprland.lua.scroll-overview = # lua
        ''
          hl.permission("${self'.legacyPackages.scrolloverview}/lib/libscrolloverview.so", "plugin", "allow")
          local function isPluginLoaded(name)
            for _, p in ipairs(hl.get_loaded_plugins()) do
              if p.name == name then
                return true
              end
            end
            return false
          end

          hl.on("config.reloaded", function()
            if isPluginLoaded("scrolloverview") then
              hl.config({
                plugin = {
                  scrolloverview = {
                    gesture_distance = 300,
                    scale = 0.40,
                    workspace_gap = 15,
                    layout = "vertical",
                    wallpaper = 0,
                    blur = false,
                    shadow = {
                      enabled = false,
                    },
                  },
                },
              })

              hl.bind("SUPER + G", function()
                hl.plugin.scrolloverview.overview("toggle all")
              end)
            end
          end)
        '';
    };

  perSystem =
    {
      self',
      inputs,
      pkgs,
      ...
    }:
    {
      legacyPackages = {
        scrolloverview = self'.packages.hyprland.stdenv.mkDerivation (finalAttrs: {
          pname = "scrolloverview";
          version = inputs._meta.scroll-overview.rev;
          src = inputs.scroll-overview;

          nativeBuildInputs = [ pkgs.pkg-config ];
          buildInputs = [
            pkgs.lua5_4
            self'.packages.hyprland
          ]
          ++ self'.packages.hyprland.buildInputs;

          enableParallelBuilding = true;
          dontUseCmakeConfigure = true;

          buildPhase = ''
            runHook preBuild
            export SCROLLOVERVIEW_BUILD_VERSION="${finalAttrs.version}"
            make all
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            mkdir -p "$out/lib"
            mv scrolloverview.so "$out/lib/libscrolloverview.so"
            runHook postInstall
          '';

          meta = {
            homepage = "https://github.com/yayuuu/hyprland-scroll-overview";
            description = "scroll overview";
            platforms = self'.packages.hyprland.meta.platforms or [ ];
          };
        });
      };
    };
}
