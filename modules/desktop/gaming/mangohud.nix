{
  exo.mods.gaming = {
    forte.gaming.mangohud = {
      enable = true;

      settings = {
        position = "top-left";
        hud_compact = true;
        round_corners = 0;
        font_size = 17;

        background_alpha = 0;
        fps = true;
        frametime = true;
        fps_limit = "60+30+0"; # careful with the fps limiter, Dark Souls 2 SOFTS doesn't like it
        fps_limit_method = "early";
        toggle_fps_limit = "Alt_L+f";
        horizontal = true;

        cpu_stats = true;

        gpu_stats = true;

        ram = true;
        vram = true;

        toggle_hud = "Alt_L+m";
      };
    };
  };
  exo.skeleton =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) mkIf mkOption types;

      cfg = config.forte.gaming.mangohud;

      settingsType =
        with types;
        (oneOf [
          bool
          int
          float
          str
          path
          (listOf (oneOf [
            int
            str
          ]))
        ]);

      renderOption =
        option:
        rec {
          int = toString option;
          float = int;
          path = int;
          bool = "0";
          string = option;
          list = lib.concatStringsSep "," (lib.lists.forEach option toString);
        }
        .${builtins.typeOf option};

      renderFormat =
        sep: suffix: attrs:
        attrs
        |> lib.mapAttrsToList (k: v: if lib.isBool v && v then k else "${k}=${renderOption v}")
        |> lib.concatStringsSep sep
        |> (str: str + suffix);

      renderSettings = renderFormat "\n" "\n";
      renderEnvString = renderFormat "," "";

    in
    {
      config = mkIf cfg.enable {
        hj.packages = [ cfg.package ];

        hj.environment.sessionVariables = {
          MANGOHUD_CONFIG = renderEnvString cfg.settings;
        };

        hj.xdg.config.files = {
          "MangoHud/MangoHud.conf" = mkIf (cfg.settings != { }) { text = renderSettings cfg.settings; };
        }
        // lib.mapAttrs' (
          n: v: lib.nameValuePair "MangoHud/${n}.conf" { text = renderSettings v; }
        ) cfg.settingsPerApplication;
      };
      options = {
        forte.gaming.mangohud = {
          enable = lib.mkEnableOption "Mangohud";

          package = lib.mkPackageOption pkgs "mangohud" { };

          settings = mkOption {
            type = with types; attrsOf settingsType;
            default = { };
            example = lib.literalExpression ''
              {
                output_folder = ~/Documents/mangohud/;
                full = true;
              }
            '';
            description = ''
              Configuration written to
              {file}`$XDG_CONFIG_HOME/MangoHud/MangoHud.conf`. See
              <https://github.com/flightlessmango/MangoHud/blob/master/data/MangoHud.conf>
              for the default configuration.
            '';
          };

          settingsPerApplication = mkOption {
            type = with types; attrsOf (attrsOf settingsType);
            default = { };
            example = {
              mpv = {
                no_display = true;
              };
            };
            description = ''
              Sets MangoHud settings per application.
              Configuration written to
              {file}`$XDG_CONFIG_HOME/MangoHud/{application_name}.conf`. See
              <https://github.com/flightlessmango/MangoHud/blob/master/data/MangoHud.conf>
              for the default configuration.
            '';
          };
        };
      };
    };
  tack.inputs.mangohud = {
    url = "gh:flightlessmango/MangoHud";
    type = "fetch";
    submodules = true;
    group = "gaming";
  };
  perSystem =
    {
      inputs,
      pkgs,
      lib,
      ...
    }:
    {
      packages.mangohud =
        let
          # Derived from subprojects/imgui.wrap
          imgui = {
            version = "1.91.6";
            src = pkgs.fetchFromGitHub {
              owner = "ocornut";
              repo = "imgui";
              tag = "v${imgui.version}";
              hash = "sha256-CLS26CRzzY4vUBgILjSQVvziHMyPGK4fwwcLZcOAzPw=";
            };
            patch = pkgs.fetchurl {
              url = "https://wrapdb.mesonbuild.com/v2/imgui_${imgui.version}-3/get_patch";
              hash = "sha256-L3l3EUugfQZVmq+IkKkqTr0lGGWS1ER5VGBaryJEY00=";
            };
          };

          # Derived from subprojects/implot.wrap
          implot = {
            version = "0.16";
            src = pkgs.fetchFromGitHub {
              owner = "epezent";
              repo = "implot";
              tag = "v${implot.version}";
              hash = "sha256-/wkVsgz3wiUVZBCgRl2iDD6GWb+AoHN+u0aeqHHgem0=";
            };
            patch = pkgs.fetchurl {
              url = "https://wrapdb.mesonbuild.com/v2/implot_${implot.version}-1/get_patch";
              hash = "sha256-HGsUYgZqVFL6UMHaHdR/7YQfKCMpcsgtd48pYpNlaMc=";
            };
          };

          # Derived from subprojects/vulkan-headers.wrap
          vulkan-headers = {
            version = "1.4.346";
            src = pkgs.fetchFromGitHub {
              owner = "KhronosGroup";
              repo = "Vulkan-Headers";
              tag = "v${vulkan-headers.version}";
              hash = "sha256-JTBW5CF5hlHWkhCjjRd08hpoAarB5W3FJbHzhQM4YFs=";
            };
          };

          # Derived from subprojects/vulkan-utility-libraries.wrap
          vulkan-utility-libraries = {
            version = "1.4.346";
            src = pkgs.fetchFromGitHub {
              owner = "KhronosGroup";
              repo = "Vulkan-Utility-Libraries";
              tag = "v${vulkan-utility-libraries.version}";
              hash = "sha256-FWZe6NdhLmI/3bm3OIK646vkWkIQ5xmBa4jlSVHSnDs=";
            };
          };

          libXNVCtrl = pkgs.linuxPackages.nvidia_x11.settings.libXNVCtrl;
          mangohud32 = pkgs.pkgsi686Linux.mangohud;

          preloadPatch =
            pkgs.writeText "preload-nix-workaround.patch" # bash
              ''
                diff --git a/bin/mangohud.in b/bin/mangohud.in
                index 927295a..58d8847 100755
                --- a/bin/mangohud.in
                +++ b/bin/mangohud.in
                @@ -15,7 +15,9 @@ cs2.sh
                 RiseOfTheTombRaider.sh
                 "

                -MANGOHUD_LIB_NAME="@ld_libdir_mangohud@@mangohud_lib_name@"
                +LD_LIBRARY_PATH="@libraryPath@''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
                +XDG_DATA_DIRS="@dataDir@''${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}"
                +MANGOHUD_LIB_NAME="@mangohud_lib_name@"

                 if [ "$1" = "--version" ]; then
                     echo @version@
                @@ -70,7 +72,7 @@ for exe in $DISABLE_LD_PRELOAD; do
                 done

                 if [ "$disable_preload" = true ]; then
                -    exec env @mangohud_env@=1 "$@"
                +    exec env @mangohud_env@=1 LD_LIBRARY_PATH="''${LD_LIBRARY_PATH}" XDG_DATA_DIRS="''${XDG_DATA_DIRS}" "$@"
                 else
                     # Make sure we don't append mangohud lib multiple times
                     # otherwise, this could cause issues with the steam runtime
                @@ -83,5 +85,5 @@ else
                             LD_PRELOAD="''${LD_PRELOAD:+:$LD_PRELOAD:}''${MANGOHUD_LIB_NAME}"
                     esac

                -    exec env @mangohud_env@=1 LD_PRELOAD="''${LD_PRELOAD}" "$@"
                +    exec env @mangohud_env@=1 LD_PRELOAD="''${LD_PRELOAD}" LD_LIBRARY_PATH="''${LD_LIBRARY_PATH}" XDG_DATA_DIRS="''${XDG_DATA_DIRS}" "$@"
                 fi
              '';

          hardcodePatch =
            pkgs.writeText "hardcode-dependencies.patch" # cpp
              ''
                diff --git a/src/dbus.cpp b/src/dbus.cpp
                index 7379af1..4eef3fe 100644
                --- a/src/dbus.cpp
                +++ b/src/dbus.cpp
                @@ -152,7 +152,7 @@ bool dbus_manager::get_media_player_metadata(metadata& meta, std::string name) {
                 }

                 bool dbus_manager::init_internal() {
                -    if (!m_dbus_ldr.IsLoaded() && !m_dbus_ldr.Load("libdbus-1.so.3")) {
                +    if (!m_dbus_ldr.IsLoaded() && !m_dbus_ldr.Load("@libdbus@/lib/libdbus-1.so.3")) {
                         SPDLOG_ERROR("Could not load libdbus-1.so.3");
                         return false;
                     }
                diff --git a/src/loaders/loader_glx.cpp b/src/loaders/loader_glx.cpp
                index aa453b8..0f6479d 100644
                --- a/src/loaders/loader_glx.cpp
                +++ b/src/loaders/loader_glx.cpp
                @@ -23,7 +23,7 @@ bool glx_loader::Load() {
                   handle = real_dlopen("glxtrace.so", RTLD_LAZY);
                 #endif
                   if (!handle)
                -    handle = real_dlopen("libGL.so.1", RTLD_LAZY);
                +    handle = real_dlopen("@libGL@/lib/libGL.so.1", RTLD_LAZY);
                   if (!handle) {
                       SPDLOG_ERROR("Failed to open " MANGOHUD_ARCH " libGL.so.1: {}", dlerror());
                       return false;
                diff --git a/src/loaders/loader_x11.cpp b/src/loaders/loader_x11.cpp
                index 214fd50..2f08857 100644
                --- a/src/loaders/loader_x11.cpp
                +++ b/src/loaders/loader_x11.cpp
                @@ -110,6 +110,6 @@ static std::shared_ptr<libx11_loader> loader;
                 std::shared_ptr<libx11_loader> get_libx11()
                 {
                     if (!loader)
                -        loader = std::make_shared<libx11_loader>("libX11.so.6");
                +        loader = std::make_shared<libx11_loader>("@libX11@/lib/libX11.so.6");
                     return loader;
                 }
                diff --git a/src/logging.cpp b/src/logging.cpp
                index 4ef7023..e24f6da 100644
                --- a/src/logging.cpp
                +++ b/src/logging.cpp
                @@ -28,8 +28,12 @@ string exec(string command) {
                 #endif
                     std::array<char, 128> buffer;
                     std::string result;
                +
                +    char* originalPath = getenv("PATH");
                +    setenv("PATH", "@path@", 1);
                     auto deleter = [](FILE* ptr){ pclose(ptr); };
                     std::unique_ptr<FILE, decltype(deleter)> pipe(popen(command.c_str(), "r"), deleter);
                +    setenv("PATH", originalPath, 1);
                     if (!pipe) {
                       return "popen failed!";
                     }
                diff --git a/src/pci_ids.cpp b/src/pci_ids.cpp
                index 002a843..5a6262b 100644
                --- a/src/pci_ids.cpp
                +++ b/src/pci_ids.cpp
                @@ -24,11 +24,9 @@ static std::istream& get_uncommented_line(std::istream& is, std::string &line)
                 void parse_pciids()
                 {
                     std::ifstream file;
                -    file.open("/usr/share/hwdata/pci.ids");
                +    file.open("@hwdata@/share/hwdata/pci.ids");
                     if (file.fail()){
                -        file.open("/usr/share/misc/pci.ids");
                -        if (file.fail())
                -            SPDLOG_ERROR("can't find file pci.ids");
                +        SPDLOG_ERROR("can't find file pci.ids");
                     }

                     std::string line;
              '';
        in
        pkgs.stdenv.mkDerivation {
          pname = "mangohud";
          version = "git";

          src = inputs.mangohud;

          # Unpack subproject sources
          postUnpack = ''
            (
              cd "$sourceRoot/subprojects"
              cp -R --no-preserve=mode,ownership ${imgui.src} imgui-${imgui.version}
              cp -R --no-preserve=mode,ownership ${implot.src} implot-${implot.version}
              cp -R --no-preserve=mode,ownership ${vulkan-headers.src} Vulkan-Headers-${vulkan-headers.version}
              cp -R --no-preserve=mode,ownership ${vulkan-utility-libraries.src} Vulkan-Utility-Libraries-${vulkan-utility-libraries.version}
            )
          '';

          patches = with pkgs; [
            preloadPatch

            (pkgs.replaceVars hardcodePatch {
              path = lib.makeBinPath [
                coreutils
                curl
                gnugrep
                gnused
                xdg-utils
              ];

              libdbus = dbus.lib;
              libGL = libGL;
              libX11 = libx11;
              inherit hwdata;
            })
          ];

          postPatch = ''
            substituteInPlace bin/mangohud.in \
              --subst-var-by libraryPath ${
                lib.makeSearchPath "lib/mangohud" [
                  (placeholder "out")
                  mangohud32
                ]
              } \
              --subst-var-by version "git" \
              --subst-var-by dataDir ${placeholder "out"}/share

            (
              cd subprojects
              unzip ${imgui.patch}
              unzip ${implot.patch}
              cp -R --no-preserve=mode,ownership packagefiles/vulkan-headers/* Vulkan-Headers-${vulkan-headers.version}
              cp -R --no-preserve=mode,ownership packagefiles/vulkan-utility-libraries/* ${vulkan-utility-libraries.src} Vulkan-Utility-Libraries-${vulkan-utility-libraries.version}
            )
          '';

          mesonFlags = [
            "-Duse_system_spdlog=enabled"
            "-Dwith_x11=enabled"
            "-Dwith_wayland=enabled"
            "-Dwith_xnvctrl=enabled"
            "-Dmangoapp=false"
            "-Dmangohudctl=false"
            "-Dwith_mangohud_next=false"
          ];

          strictDeps = true;

          nativeBuildInputs = with pkgs; [
            addDriverRunpath
            appstream
            glslang
            python3Packages.mako
            meson
            ninja
            pkg-config
            unzip
          ];

          buildInputs = with pkgs; [
            dbus
            spdlog
            wayland
            libx11
            libGL
            libXNVCtrl
            libxkbcommon
            libdrm
            vulkan-loader
          ];

          postInstall = ''
            ln -s ${mangohud32}/share/vulkan/implicit_layer.d/MangoHud.x86.json \
              "$out/share/vulkan/implicit_layer.d"
          '';

          postFixup = ''
            substituteInPlace $out/share/vulkan/implicit_layer.d/MangoHud.x86_64.json \
              --replace-fail "VK_LAYER_MANGOHUD_overlay" "VK_LAYER_MANGOHUD_overlay_64"

            # Add OpenGL driver and libXNVCtrl paths to RUNPATH to support NVIDIA cards
            addDriverRunpath "$out/lib/mangohud/libMangoHud.so"
            patchelf --add-rpath ${libXNVCtrl}/lib "$out/lib/mangohud/libMangoHud.so"
          '';
        };
    };
}
