{
  tack.inputs.hypr-plugs = {
    url = "gh:hyprwm/hyprland-plugins";
    type = "fetch";
    group = "hypr";
    patches = [ "https://github.com/hyprwm/hyprland-plugins/pull/715" ];
  };
  exo.mods.desktop = { self', ... }: {
    forte.hyprland.plugins = [ self'.legacyPackages.borders-plus-plus ];
    forte.hyprland.lua.borders-plus-plus = # lua
      ''
        hl.permission("${self'.legacyPackages.borders-plus-plus}/lib/libborders-plus-plus.so", "plugin", "allow")
        local function isPluginLoaded(name)
          for _, p in ipairs(hl.get_loaded_plugins()) do
            if p.name == name then
              return true
            end
          end
          return false
        end

        hl.on("config.reloaded", function()
          if isPluginLoaded("borders-plus-plus") then
            hl.config({
              plugin = {
                borders_plus_plus = {
                  add_borders = 2,
                  natural_rounding = false,
                  col = {
                    border_1 = "#131313",
                    border_2 = "#151515",
                  },
                  border_size_1 = 2,
                  border_size_2 = 5,
                }
              }
            })
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
        borders-plus-plus = self'.packages.hyprland.stdenv.mkDerivation (finalAttrs: {
          pname = "borders-plus-plus";
          version = inputs._meta.hypr-plugs.rev;
          src = inputs.hypr-plugs;

          nativeBuildInputs = [ pkgs.pkg-config ];
          buildInputs = [ self'.packages.hyprland ] ++ self'.packages.hyprland.buildInputs;

          sourceRoot = "source/borders-plus-plus";

          enableParallelBuilding = true;
          dontUseCmakeConfigure = true;

          installPhase = ''
            runHook preInstall
            mkdir -p "$out/lib"
            mv borders-plus-plus.so "$out/lib/libborders-plus-plus.so"
            runHook postInstall
          '';
        });
      };
    };
}
