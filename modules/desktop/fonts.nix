{
  exo.mods.desktop =
    { pkgs, self', ... }:
    {
      fonts = {
        packages =
          with pkgs;
          [
            nerd-fonts.symbols-only
            montserrat
            maple-mono.NF
          ]
          ++ (with self'.legacyPackages.apple-fonts; [
            sf-pro
            sf-mono
            sf-compact
            emoji
          ]);
        enableDefaultPackages = true;
        fontDir.enable = true;
        fontconfig = {
          enable = true;
          antialias = true;
          hinting = {
            enable = true;
            style = "full";
            autohint = false;
          };
          subpixel = {
            rgba = "rgb";
            lcdfilter = "light";
          };
          defaultFonts = {
            serif = [ "SF Compact Rounded" ];
            sansSerif = [ "SF Pro Text" ];
            monospace = [ "Maple Mono NF" ];
            emoji = [ "Apple Color Emoji" ];
          };
        };
      };
    };
  perSystem =
    { pkgs, inputs, ... }:
    let
      makeAppleFont =
        name: pkgName: src:
        pkgs.stdenvNoCC.mkDerivation {
          allowSubstitutes = false;
          preferLocalBuild = true;

          inherit name src;

          unpackPhase = ''
            runHook preUnpack
            7z x $src
            if [ ! -f 'Payload~' ]; then
              7z x './*/${pkgName}'
            fi
            7z x -tcpio 'Payload~'
            runHook postUnpack
          '';

          nativeBuildInputs = [
            pkgs.p7zip
            pkgs.installFonts
          ];

          setSourceRoot = "sourceRoot=`pwd`";
        };
    in
    {
      legacyPackages = {
        apple-fonts = {
          sf-pro = makeAppleFont "sf-pro" "SF Pro Fonts.pkg" inputs.sf-pro;
          sf-mono = makeAppleFont "sf-mono" "SF Mono Fonts.pkg" inputs.sf-mono;
          sf-compact = makeAppleFont "sf-compact" "SF Compact Fonts.pkg" inputs.sf-compact;
          emoji = pkgs.stdenvNoCC.mkDerivation {
            allowSubstitutes = false;
            preferLocalBuild = true;

            name = "apple-font-emoji";
            src = inputs.apple-font-emoji;
            dontUnpack = true;
            dontBuild = true;
            dontConfigure = true;
            installPhase = ''
              install -D -m644 $src $out/share/fonts/truetype/AppleColorEmoji-Linux.ttf
            '';
          };
        };
      };
    };
  tack = {
    shorturls.applefont = "https://devimages-cdn.apple.com/design/resources/download/{path}";
    inputs =
      {
        sf-pro = "applefont:SF-Pro.dmg";
        sf-mono = "applefont:SF-Mono.dmg";
        sf-compact = "applefont:SF-Compact.dmg";
        apple-font-emoji = "https://github.com/samuelngs/apple-emoji-ttf/releases/download/macos-26-20260613-f1fc560b/AppleColorEmoji-Linux.ttf";
      }
      |> builtins.mapAttrs (
        _: url: {
          inherit url;
          type = "fixed";
          group = "fonts";
          frozen = true;
        }
      );
  };
}
