{
  exo.mods.media =
    {
      lib,
      config,
      self',
      ...
    }:
    let
      cfg = config.forte.jellium-desktop;
    in
    {
      config = lib.mkIf cfg.enable {
        hj.packages = [ cfg.package ];
        forte.persist.home.directories = [
          ".cache/jellium-desktop"
          ".config/jellium-desktop"
        ];
        forte.hyprland.lua.window-rules = # lua
          ''
            hl.window_rule({
              name             = "jellium-desktop",
              match            = { class = "net.nullsum.JelliumDesktop" },
              workspace        = "6",
              opacity          = "1 override",
              idle_inhibit = "focus",
            })
          '';
      };

      options.forte.jellium-desktop = {
        enable = lib.mkEnableOption "jellium-desktop" // {
          default = true;
        };
        package = lib.mkOption {
          type = lib.types.package;
          default = self'.packages.jellium-desktop;
        };
      };
    };
  tack.inputs.jellium-desktop = {
    url = "gh:andrewrabert/jellium-desktop";
    patches = [ "https://github.com/andrewrabert/jellium-desktop/pull/717" ];
    frozen = true;
    submodules = true;
    type = "fetch";
    group = "desktop";
  };
  perSystem =
    {
      pkgs,
      inputs,
      self',
      ...
    }:
    {
      remotePackages = {
        jellium-desktop = pkgs.callPackage (
          {
            # Nix/Rust packaging helpers
            lib,
            runCommand,
            rustPlatform,
            autoPatchelfHook,
            makeWrapper,

            # CEF
            cef-binary,

            # Build tools and generators
            meson,
            ninja,
            cmake,
            python3,
            pkg-config,
            llvmPackages,

            # Core media playback and codecs
            ffmpeg,
            libass,
            libplacebo,

            # OpenGL/GBM and display infrastructure
            libGL,
            libgbm,
            libdrm,
            libdisplay-info,

            # X11 support
            libx11,
            libxcb,
            libxext,
            libxrandr,
            libxfixes,
            libxpresent,
            libxscrnsaver,

            # Wayland support
            wayland,
            libxkbcommon,
            wayland-scanner,
            wayland-protocols,

            # Hardware video acceleration
            libva,
            vulkan-loader,
            vulkan-headers,
            nv-codec-headers-12,

            # Network and disc media support
            curl,
            libcdio,

            # Archive and scripting support
            lua,
            mujs,
            libarchive,

            # Audio processing and output
            alsa-lib,
            pipewire,
            rubberband,
            pulseaudio,
            libcdio-paranoia,

            # Image, terminal graphics, and visual output
            lcms2,
            libjpeg_turbo,

            # Subtitle/text encoding and video filters
            zimg,
            libuchardet,

            libglvnd,
            mesa,

          }:
          let
            cef = runCommand "cef-jellium" { } ''
              mkdir -p "$out"

              # Jellium Desktop expects a flat structure
              cp -r ${cef-binary}/include "$out"
              cp -r ${cef-binary}/Release/* "$out"
              cp -r ${cef-binary}/Resources/* "$out"

              chmod -R u+w "$out"
            '';
          in
          rustPlatform.buildRustPackage {
            pname = "jellium-desktop";
            version = inputs._meta.jellium-desktop.rev;
            __structuredAttrs = true;

            env = {
              CEF_PATH = "${cef}";
              LIBCLANG_PATH = "${lib.getLib llvmPackages.libclang}/lib";
            };

            src = inputs.jellium-desktop;

            cargoRoot = "src";
            cargoLock = {
              lockFile = "${inputs.jellium-desktop}/src/Cargo.lock";
              outputHashes = {
                "cryoglyph-0.1.0" = "sha256-KJeEzzp5UCsF6Q2VlfHdjsY+N8vzTjgEZUAZtlIpfiU=";
                "iced_core-0.15.0-dev" = "sha256-cZhPMpqeCsHfXCmqOumVaw1k3Y3r2cNzqmifmtE3UlI=";
              };
            };

            patchPhase = "patchShebangs third_party/mpv ";

            buildPhase = ''
              runHook preBuild

              cargo run                             \
              --release                             \
              --manifest-path src/xtask/Cargo.toml  \
              -- build --cef-path ${cef}

              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall

              appDir="$out/lib/jellium-desktop"
              mkdir -p "$appDir" "$out/bin"

              install -Dm755 build/libmpv.so.2 "$appDir/libmpv.so.2"
              install -Dm755 build/jellium-desktop "$appDir/jellium-desktop"
              install -Dm644 resources/linux/net.nullsum.JelliumDesktop.desktop \
                              "$out/share/applications/net.nullsum.JelliumDesktop.desktop"
              install -Dm644 resources/linux/net.nullsum.JelliumDesktop.metainfo.xml \
                              "$out/share/metainfo/net.nullsum.JelliumDesktop.metainfo.xml"
              install -Dm644 resources/linux/net.nullsum.JelliumDesktop.svg \
                              "$out/share/icons/hicolor/scalable/apps/net.nullsum.JelliumDesktop.svg"

              makeWrapper "$appDir/jellium-desktop" "$out/bin/jellium-desktop" \
                --set CEF_PATH "${cef}" \
                --prefix LD_LIBRARY_PATH : "$appDir:${cef}:/run/opengl-driver/lib:${
                  lib.makeLibraryPath [
                    libglvnd
                    mesa
                    vulkan-loader
                  ]
                }" \
                --prefix XDG_DATA_DIRS : "/run/opengl-driver/share" \
                --add-flags "--platform-paint dmabuf --platform=wayland --hwdec=yes"
            '';

            doCheck = false;

            autoPatchelfIgnoreMissingDeps = [ "libcef.so" ];

            nativeBuildInputs = [
              pkg-config
              meson
              ninja
              cmake
              python3
              llvmPackages.clang
              autoPatchelfHook
              makeWrapper
              wayland-scanner
            ];

            buildInputs = [
              alsa-lib
              cef
              curl
              ffmpeg
              lcms2
              libGL
              libarchive
              libass
              libcdio
              libcdio-paranoia
              libdisplay-info
              libdrm
              libgbm
              libjpeg_turbo
              libplacebo
              libuchardet
              libva
              libx11
              libxcb
              libxext
              libxfixes
              libxkbcommon
              libxpresent
              libxrandr
              libxscrnsaver
              lua
              mujs
              nv-codec-headers-12
              pipewire
              pulseaudio
              rubberband
              vulkan-headers
              vulkan-loader
              wayland
              wayland-protocols
              zimg
            ];
          }
        ) { cef-binary = self'.packages.cef-binary; };
        cef-binary = pkgs.callPackage (
          {
            lib,
            stdenv,
            fetchurl,
            glib,
            nss,
            nspr,
            atk,
            at-spi2-atk,
            libdrm,
            expat,
            libxkbcommon,
            libgbm,
            gtk3,
            pango,
            cairo,
            alsa-lib,
            dbus,
            at-spi2-core,
            cups,
            libGL,
            udev,
            systemdLibs,
            libxrandr,
            libxfixes,
            libxext,
            libxdamage,
            libxcomposite,
            libx11,
            libxshmfence,
            libxcb,
            version ? "156.0.14",
            gitRevision ? "4fa4ab5",
            chromiumVersion ? "156.0.8078.48",
            buildType ? "Release",
            srcHashes ? {
              aarch64-linux = "sha256-zfzVyvqhJrt+ED47b73vlKObt5E5XrIf5mXr7NAI2ZU=";
              x86_64-linux = "sha256-QZGskgqRoFLroEr7btgw1HrtRqPiRsQ0ovBiwjWI3Io=";
            },
          }:

          let
            gl_rpath = lib.makeLibraryPath [ stdenv.cc.cc ];

            rpath = lib.makeLibraryPath [
              glib
              nss
              nspr
              atk
              at-spi2-atk
              libdrm
              expat
              libxkbcommon
              libgbm
              gtk3
              pango
              cairo
              alsa-lib
              dbus
              at-spi2-core
              cups
              libGL
              udev
              systemdLibs
              libxcb
              libx11
              libxcomposite
              libxdamage
              libxext
              libxfixes
              libxrandr
              libxshmfence
            ];

            selectSystem =
              attrs:
              attrs.${stdenv.hostPlatform.system} or (throw "Unsupported system ${stdenv.hostPlatform.system}");
          in
          stdenv.mkDerivation {
            pname = "cef-binary";
            inherit version;

            src = fetchurl {
              url = "https://cef-builds.spotifycdn.com/cef_binary_${version}+g${gitRevision}+chromium-${chromiumVersion}_${
                selectSystem {
                  aarch64-linux = "linuxarm64";
                  x86_64-linux = "linux64";
                }
              }_minimal.tar.bz2";
              hash = selectSystem srcHashes;
            };

            stripDebugList = [ "Release" ];

            dontPatchELF = true;

            installPhase = ''
              runHook preInstall

              sed 's/-O0/-O2/' -i cmake/cef_variables.cmake
              patchelf --set-rpath "${rpath}" --set-interpreter "${stdenv.cc.bintools.dynamicLinker}" ${buildType}/chrome-sandbox
              patchelf --add-needed libudev.so --set-rpath "${rpath}" ${buildType}/libcef.so
              patchelf --set-rpath "${gl_rpath}" ${buildType}/libvk_swiftshader.so
              patchelf --set-rpath "${gl_rpath}" ${buildType}/libvulkan.so.1
              [ -f ${buildType}/libEGL.so ] && patchelf --set-rpath "${gl_rpath}" ${buildType}/libEGL.so
              [ -f ${buildType}/libGLESv2.so ] && patchelf --add-needed libGL.so.1 --set-rpath "${gl_rpath}" ${buildType}/libGLESv2.so
              cp --recursive . $out

              runHook postInstall
            '';
          }
        ) { };
      };
    };
}
