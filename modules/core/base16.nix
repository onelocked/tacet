{ lib, ... }:
{
  config = {
    schemes = {
      dark = {
        # Backgrounds
        base00 = "#131316";
        base01 = "#221c2c";
        base02 = "#313245";
        base03 = "#4D415F";

        # Foregrounds
        base04 = "#8c92aa";
        base05 = "#cfd3e7";
        base06 = "#e4e8f5";
        base07 = "#f0f2fa";

        # Accents
        base08 = "#f4a8b8";
        base09 = "#f2b8a0";
        base0A = "#f6d88a";
        base0B = "#b8db8c";
        base0C = "#7cb8d4";
        base0D = "#c5c0ff";
        base0E = "#c8b0e8";
        base0F = "#7d75c0";

        # Extended
        base10 = "#130f18";
        base11 = "#0c0a10";
        base12 = "#ff7a6b";
        base13 = "#f6d88a";
        base14 = "#c8e09c";
        base15 = "#8fd4b5";
        base16 = "#a8c8f0";
        base17 = "#e8c4d8";
      };
      monochrome = {
        # Backgrounds
        base00 = "#131313";
        base01 = "#1b1b1f";
        base02 = "#2a2a2f";
        base03 = "#46464d";

        # Foregrounds
        base04 = "#8a8a92";
        base05 = "#cfcfd4";
        base06 = "#e4e4e8";
        base07 = "#f2f2f4";

        # Accents
        base08 = "#c97f8c";
        base09 = "#c99a82";
        base0A = "#c3ad70";
        base0B = "#8fb577";
        base0C = "#bcbcc2";
        base0D = "#a0a0a8";
        base0E = "#8a8a92";
        base0F = "#6e6e76";

        # Extended
        base10 = "#0e0e11";
        base11 = "#09090b";
        base12 = "#d0756a";
        base13 = "#c3ad70";
        base14 = "#a3bb82";
        base15 = "#78ae95";
        base16 = "#d0d0d6";
        base17 = "#c79db6";
      };
    };
    _module.args =
      let
        #
        # This serves as a highly stripped down base16.nix that has no dependency on pkgs
        #
        # This does not support loading files, and instead of withHashtag I have inverted this to noHashtag
        #
        # much of the following code is directly lifted or adapted from here:
        #   https://github.com/SenchoPens/base16.nix/blob/75ed5e5e3fce37df22e49125181fa37899c3ccd6/lib/colors.nix
        primaryHex2Dec =
          hex:
          let
            hex2decDigits = rec {
              "0" = 0;
              "1" = 1;
              "2" = 2;
              "3" = 3;
              "4" = 4;
              "5" = 5;
              "6" = 6;
              "7" = 7;
              "8" = 8;
              "9" = 9;
              A = 10;
              B = 11;
              C = 12;
              D = 13;
              E = 14;
              F = 15;
              a = A;
              b = B;
              c = C;
              d = D;
              e = E;
              f = F;
            };
          in
          16 * hex2decDigits."${builtins.substring 0 1 hex}" + hex2decDigits."${builtins.substring 1 1 hex}";

        hexToRgb = hex: {
          r = primaryHex2Dec (builtins.substring 0 2 hex);
          g = primaryHex2Dec (builtins.substring 2 2 hex);
          b = primaryHex2Dec (builtins.substring 4 2 hex);
        };

        ensureBase24 =
          scheme:
          {
            base10 = scheme.base00;
            base11 = scheme.base00;
            base12 = scheme.base08;
            base13 = scheme.base0A;
            base14 = scheme.base0B;
            base15 = scheme.base0C;
            base16 = scheme.base0D;
            base17 = scheme.base0E;
          }
          // scheme;

        addMnemonicNames =
          scheme:
          {
            red = scheme.base08;
            orange = scheme.base09;
            yellow = scheme.base0A;
            green = scheme.base0B;
            cyan = scheme.base0C;
            blue = scheme.base0D;
            magenta = scheme.base0E;
            brown = scheme.base0F;
            bright-red = scheme.base12;
            bright-yellow = scheme.base13;
            bright-green = scheme.base14;
            bright-cyan = scheme.base15;
            bright-blue = scheme.base16;
            bright-magenta = scheme.base17;
          }
          // scheme;

        round =
          float: # 4.2
          let
            int = builtins.floor float; # 4
            decimal = float - int; # 4.2 - 4 = 0.2
          in
          if decimal < 0.5 then int else builtins.ceil float;

        stripHashtag = lib.removePrefix "#";
      in
      {
        averageColors =
          {
            startColor,
            endColor,
            steps ? 1.0,
          }:
          let
            startRgb = hexToRgb (stripHashtag startColor);
            endRgb = hexToRgb (stripHashtag endColor);

            deltas = {
              r = startRgb.r - endRgb.r;
              g = startRgb.g - endRgb.g;
              b = startRgb.b - endRgb.b;
            };

            partials = deltas |> lib.mapAttrs (_: c: c / (steps + 1.0));
          in
          steps
          |> builtins.genList (
            i: startRgb |> lib.mapAttrs (n: v: lib.trivial.toHexString (round (v + ((i + 1) * partials.${n}))))
          )
          |> map (v: "#${v.r}${v.g}${v.b}");

        mkScheme =
          schema:
          let
            scheme = schema |> ensureBase24 |> addMnemonicNames;
            noHashtag = scheme |> lib.mapAttrs (_: v: stripHashtag v);
            asRgb8 = noHashtag |> lib.mapAttrs (_: v: hexToRgb v);
            asRgb = asRgb8 |> lib.mapAttrs (_: rgb: lib.mapAttrs (_: c: c / 256.0) rgb);
          in
          scheme // { inherit noHashtag asRgb8 asRgb; };
      };
  };
  options.schemes = lib.mkOption {
    type = lib.types.attrsOf lib.types.attrs;
    description = "A set of base16/24 colorschemes";
  };
}
