{
  exo.mods.desktop =
    {
      scheme,
      theme,
      lib,
      pkgs,
      ...
    }:
    {
      forte.kitty = {
        enable = true;
        settings = {
          wayland_enable_ime = "no";

          sync_to_monitor = "yes";
          background_opacity = "0.93";
          remember_window_position = "no";

          draw_minimal_borders = "yes";
          placement_strategy = "center";
          update_check_interval = "24";
          allow_hyperlinks = "yes";
          allow_remote_control = "yes";
          listen_on = "unix:/tmp/kitty-\${kitty_pid}";

          scrollback_lines = "10000";
          wheel_scroll_multiplier = "5.0";

          strip_trailing_spaces = "smart";
          hide_window_decorations = "yes";

          enable_audio_bell = "no";
          visual_bell_duration = "0.0";
          repaint_delay = "10";

          confirm_os_window_close = "0";

          cursor_trail = "1";
          cursor_trail_decay = "0.1 0.2";
          cursor_shape = "block";
          cursor_blink_interval = "0.5";
          cursor_stop_blinking_after = "15.0";
          enabled_layouts = "splits,stack";

          window_padding_width = "0 0 0 0";

          detect_urls = "yes";
          url_style = "curly";
          mouse_hide_wait = "2.0";

          focus_follows_mouse = "no";
          cursor_shape_unfocused = "hollow";

          # Tab bar
          tab_bar_edge = "bottom";
          tab_bar_style = "custom";
          tab_bar_align = "center";
          tab_bar_min_tabs = "2";

          tab_title_max_length = "1";
          tab_title_template = "{fmt.fg._313244}●";
          active_tab_title_template = "{fmt.fg._c5c0ff}{'' if layout_name == 'stack' else '●'}";

          active_tab_font_style = "normal";
          inactive_tab_font_style = "normal";

          window_border_width = "1.5pt";
        };
        keybindings = {
          # Splits
          "ctrl+a>p>d" = "launch --location=hsplit --cwd=current";
          "ctrl+a>p>n" = "launch --location=vsplit --cwd=current";
          "ctrl+n" = "combine : launch --location=hsplit --cwd=current: layout_action bias 20";
          "alt+f" = "toggle_layout stack";

          # Navigation with Alt + arrows
          "alt+left" = "neighboring_window left";
          "alt+right" = "neighboring_window right";
          "alt+up" = "neighboring_window up";
          "alt+down" = "neighboring_window down";

          # Resize panes
          "ctrl+alt+left" = "resize_window narrower";
          "ctrl+alt+right" = "resize_window wider";
          "ctrl+alt+up" = "resize_window taller";
          "ctrl+alt+down" = "resize_window shorter";
          "ctrl+a>r" = "start_resizing_window";

          # --- Tab Management ---
          # Create a new tab
          "ctrl+a>c" = "new_tab_with_cwd";

          # Switch to specific tabs (1 through 9)
          "ctrl+a>1" = "goto_tab 1";
          "ctrl+a>2" = "goto_tab 2";
          "ctrl+a>3" = "goto_tab 3";
          "ctrl+a>4" = "goto_tab 4";
          "ctrl+a>5" = "goto_tab 5";
          "ctrl+a>6" = "goto_tab 6";
          "ctrl+a>7" = "goto_tab 7";
          "ctrl+a>8" = "goto_tab 8";
          "ctrl+a>9" = "goto_tab 9";
        };
        mouseBindings = {
          "right press ungrabbed" = "combine : copy_to_clipboard : clear_selection";
          "left press ungrabbed" = "mouse_selection drag_or_normal_select";
        };
        extraConfig = ''
          # scrollback-kitty nvim plugin
          action_alias kitty_scrollback_nvim kitten ${pkgs.vimPlugins.kitty-scrollback-nvim}/python/kitty_scrollback_nvim.py
          map alt+a kitty_scrollback_nvim
          map alt+g kitty_scrollback_nvim --config ksb_builtin_last_cmd_output
          mouse_map ctrl+shift+right press ungrabbed combine : mouse_select_command_output : kitty_scrollback_nvim --config ksb_builtin_last_visited_cmd_output

          map alt+h kitten hints --type regex --regex 'sha256-[A-Za-z0-9+/=]{44}' --program @
        '';
        fontConfig =
          let
            mapleFeatures = "+cv01 +cv04 +cv05 +cv06 +cv07 +cv08 +cv32 +cv34 +cv36 +cv37 +cv39 +cv40 +cv41 +cv66 +ss03 +ss04 +ss05 +ss06 +ss07 +ss08 +ss09 +ss10 +ss11 +zero";
          in
          {
            text_composition_strategy = "legacy";
            font_family = ''family="Maple Mono NF" style="ExtraBold"'';
            bold_font = ''family="Montserrat" style="Black"'';
            italic_font = ''family="Maple Mono NF" style="Bold Italic"'';
            bold_italic_font = ''family="Maple Mono NF" style="ExtraBold Italic"'';
            font_size = "10.5";
            disable_ligatures = "never";
            "font_features MapleMono-NF-Bold" = mapleFeatures;
            "font_features MapleMono-NF-ExtraBold" = mapleFeatures;
            "font_features MapleMono-NF-BoldItalic" = mapleFeatures;
            "font_features MapleMono-NF-ExtraBoldItalic" = mapleFeatures;
          };
        theme = with scheme; {
          # Normal colors (0–7)
          color0 = base00;
          color1 = base08;
          color2 = base0B;
          color3 = base0A;
          color4 = base0D;
          color5 = base0E;
          color6 = base0C;
          color7 = base05;

          # Bright colors
          color8 = base03;
          color9 = base12;
          color10 = base14;
          color11 = base09;
          color12 = base0D;
          color13 = base17;
          color14 = base15;
          color15 = base07;

          background = base00;
          foreground = base05;
          cursor = base0D;
          cursor_text_color = base00;
          cursor_trail_color = base0E;

          # Selection
          selection_background = base0D;
          selection_foreground = base02;

          # Borders
          active_border_color = base0D;
          inactive_border_color = base03;
          url_color = base0E;

          # Tabs
          active_tab_foreground = base0D;
          active_tab_background = base02;
          inactive_tab_foreground = base04;
          inactive_tab_background = base00;
        };
      };
    };
  exo.skeleton =
    {
      wrapPackage,
      lib,
      config,
      pkgs,
      ...
    }:
    let
      cfg = config.forte.kitty;
      inherit (lib)
        types
        mkOption
        literalExpression
        ;

      settingsValueType =
        with types;
        oneOf [
          str
          bool
          int
          float
        ];
    in
    {
      config = lib.mkIf (cfg.enable) {
        hj.packages = [ cfg.package ];
        xdg.terminal-exec.settings = {
          default = [ "kitty.desktop" ];
        };
        forte.hyprland.lua = {
          window-rules = # lua
            ''
              hl.window_rule({
                name             = "kitty",
                match            = { class = "kitty" },
                opacity          = "1 override 1 override",
                fullscreen_state = "0 1",
              })
              hl.window_rule({
                name  = "kitty-scroll",
                match = { class = "kitty", workspace = "r[2-3] w[t3-99]" },
                scrolling_width = 0.333,
              })
            '';
          keybinds = # lua
            ''
              hl.bind("SUPER + T", hl.dsp.exec_raw("kitty -1"))
            '';
        };
        xdg.mime.defaultApplications =
          [
            "terminal"
            "x-terminal-emulator"
            "inode/directory"
          ]
          |> map (mime: lib.nameValuePair mime [ "kitty.desktop" ])
          |> lib.listToAttrs;

        programs.fish.interactiveShellInit =
          lib.mkIf cfg.shellIntegration.enableFishIntegration # fish
            ''
              if set -q KITTY_INSTALLATION_DIR
                set --global KITTY_SHELL_INTEGRATION "${cfg.shellIntegration.mode}"
                source "$KITTY_INSTALLATION_DIR/shell-integration/fish/vendor_conf.d/kitty-shell-integration.fish"
                set --prepend fish_complete_path "$KITTY_INSTALLATION_DIR/shell-integration/fish/vendor_completions.d"
              end
            '';
      };
      options.forte.kitty = {
        enable = lib.mkEnableOption "kitty";
        package = lib.mkOption {
          type = lib.types.package;
          default =
            let
              toKittyConfig = lib.generators.toKeyValue {
                mkKeyValue =
                  key: value:
                  let
                    yesNo = v: if v then "yes" else "no";
                    value' = (if builtins.isBool value then yesNo else toString) value;
                  in
                  "${key} ${value'}";
              };
            in
            wrapPackage {
              package = pkgs.kitty;
              files.configuration = {
                "kitty.conf" = ''
                  # Settings
                  ${toKittyConfig cfg.settings}

                  # Theme
                  ${toKittyConfig cfg.theme}

                  # Font Config
                  ${toKittyConfig cfg.fontConfig}

                  # Keybindings
                  ${toKittyConfig cfg.keybindings}

                  # Mouse Bindings
                  ${toKittyConfig cfg.mouseBindings}

                  # Shell Integration
                  ${lib.optionalString (
                    cfg.shellIntegration.mode != null
                  ) "shell_integration ${cfg.shellIntegration.mode}"}

                  # Extra config options
                  ${cfg.extraConfig}
                '';
              };
              env.KITTY_CONFIG_DIRECTORY = "${wrapPackage.out'}/configuration";
            };
        };
        settings = mkOption {
          type = types.attrsOf settingsValueType;
          default = { };
          example = literalExpression ''
            {
              scrollback_lines = 10000;
              enable_audio_bell = false;
              update_check_interval = 0;
            }
          '';
          description = ''
            Key/value pairs written into `kitty.conf`.
            See <https://sw.kovidgoyal.net/kitty/conf.html>.
          '';
        };
        theme = mkOption {
          type = types.attrsOf types.str;
          default = { };
          description = "Color scheme attributes for kitty, structurally merged into settings.";
          example = literalExpression ''
            {
              color0 = "#131316";
              background = "#131316";
            }
          '';
        };

        fontConfig = mkOption {
          type = types.attrsOf types.str;
          default = { };
          description = "Font configuration for kitty";
        };

        extraConfig = mkOption {
          default = "";
          type = types.lines;
          description = "Additional configuration to add to kitty.conf.";
        };

        keybindings = mkOption {
          type = types.attrsOf types.str;
          default = { };
          apply = lib.mapAttrs' (name: value: lib.nameValuePair ("map " + name) value);
          example = literalExpression ''
            {
              "ctrl+c" = "copy_or_interrupt";
              "ctrl+f>2" = "set_font_size 20";
            }
          '';
          description = "Mapping of keybindings to actions.";
        };

        mouseBindings = mkOption {
          type = types.attrsOf types.str;
          default = { };
          apply = lib.mapAttrs' (name: value: lib.nameValuePair ("mouse_map " + name) value);
          description = "Mapping of mouse bindings to actions.";
          example = literalExpression ''
            {
              "ctrl+left click" = "ungrabbed mouse_handle_click selection link prompt";
              "left click" = "ungrabbed no-op";
            };
          '';
        };

        shellIntegration = {
          mode = mkOption {
            type = types.nullOr types.str;
            default = "no-rc";
            example = "no-cursor";
            apply = lib.mapNullable (
              o:
              let
                modes = lib.splitString " " o;
                filtered = lib.filter (m: m != "no-rc") modes;
              in
              lib.concatStringsSep " " ([ "no-rc" ] ++ filtered)
            );
            description = ''
              Set the mode of the shell integration. This accepts the same options
              as the `shell_integration` option of Kitty. Note that
              `no-rc` is always implied, unless this set to `null`.
            '';
          };
          enableFishIntegration = lib.mkEnableOption "fish integration" // {
            default = true;
          };
        };
      };
    };
}
