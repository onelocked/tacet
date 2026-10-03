{
  exo.mods.desktop =
    {
      scheme,
      pkgs,
      ...
    }:
    {
      forte = {
        gtk = {
          icons = {
            name = "Papirus-Dark";
            package = pkgs.papirus-icon-theme;
          };
          theme = {
            name = "adw-gtk3-dark";
            package = pkgs.adw-gtk3;
            css =
              with scheme; # css
              ''
                @define-color accent_color ${base0F};
                @define-color accent_bg_color ${base0F};
                @define-color accent_fg_color ${base0D};
                @define-color destructive_bg_color ${base08};
                @define-color destructive_fg_color ${base10};
                @define-color error_bg_color ${base08};
                @define-color error_fg_color ${base10};
                @define-color window_bg_color ${base00};
                @define-color window_fg_color ${base07};
                @define-color view_bg_color ${base00};
                @define-color view_fg_color ${base07};
                @define-color headerbar_bg_color ${base00};
                @define-color headerbar_fg_color ${base07};
                @define-color headerbar_backdrop_color @window_bg_color;
                @define-color popover_bg_color ${base01};
                @define-color popover_fg_color ${base07};
                @define-color card_bg_color ${base01};
                @define-color card_fg_color ${base07};
                @define-color dialog_bg_color ${base00};
                @define-color dialog_fg_color ${base07};
                @define-color overview_bg_color ${base01};
                @define-color overview_fg_color ${base07};
                @define-color sidebar_bg_color ${base01};
                @define-color sidebar_fg_color ${base07};
                @define-color sidebar_backdrop_color @window_bg_color;
                @define-color sidebar_border_color @window_bg_color;
                @define-color secondary_sidebar_bg_color ${base00};
                @define-color secondary_sidebar_fg_color ${base07};
                /* Backdrop/unfocused states */
                @define-color theme_unfocused_fg_color @window_fg_color;
                @define-color theme_unfocused_text_color @view_fg_color;
                @define-color theme_unfocused_bg_color @window_bg_color;
                @define-color theme_unfocused_base_color @window_bg_color;
                @define-color theme_unfocused_selected_bg_color @accent_bg_color;
                @define-color theme_unfocused_selected_fg_color @accent_fg_color;
                :root {
                    --accent-color: ${base0F};
                    --accent-bg-color: ${base0F};
                    --accent-fg-color: ${base0D};
                    --destructive-bg-color: ${base08};
                    --destructive-fg-color: ${base10};
                    --error-bg-color: ${base08};
                    --error-fg-color: ${base10};
                    --error-color: ${base08};
                    --window-bg-color: ${base00};
                    --window-fg-color: ${base07};
                    --view-bg-color: ${base00};
                    --view-fg-color: ${base07};
                    --headerbar-bg-color: ${base00};
                    --headerbar-fg-color: ${base07};
                    --headerbar-backdrop-color: @window_bg_color;
                    --popover-bg-color: ${base01};
                    --popover-fg-color: ${base07};
                    --card-bg-color: ${base01};
                    --card-fg-color: ${base07};
                    --dialog-bg-color: ${base00};
                    --dialog-fg-color: ${base07};
                    --overview-bg-color: ${base01};
                    --overview-fg-color: ${base07};
                    --sidebar-bg-color: ${base01};
                    --sidebar-fg-color: ${base07};
                    --sidebar-backdrop-color: @window_bg_color;
                    --sidebar-border-color: @window_bg_color;
                    --warning-bg-color: ${base02};
                    --warning-fg-color: ${base17};
                    --warning-color: ${base0E};
                    --success-color: ${base05};
                    --success-bg-color: ${base02};
                    --success-fg-color: ${base06};
                    --shade-color: rgba(0, 0, 0, 0.36);
                }
              '';
          };
        };
      };
    };
}
