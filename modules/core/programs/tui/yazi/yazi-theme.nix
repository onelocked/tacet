{
  exo.core =
    { lib, scheme, ... }:
    {
      forte.yazi = with scheme; {
        theme.flavor = lib.genAttrs [ "dark" "light" ] (_: "oneshill");
        flavorContent = # toml
          ''
            [mgr]
            border_set = { as = "plain" }
            cwd = { fg = "${base05}" }

            find_keyword = { fg = "${base08}", bold = true, italic = true, underline = true }
            find_position = { fg = "${base08}", bold = true, italic = true }

            marker_copied = { fg = "${base0F}", bg = "${base0F}" }
            marker_cut = { fg = "${base0F}", bg = "${base0F}" }
            marker_marked = { fg = "${base08}", bg = "${base08}" }
            marker_selected = { fg = "${base0E}", bg = "${base0E}" }

            count_copied = { fg = "${base17}", bg = "${base0F}" }
            count_cut = { fg = "${base17}", bg = "${base0F}" }
            count_selected = { fg = "${base07}", bg = "${base0E}" }

            border_style  = { fg = "${base0D}" }


            [indicator]
            padding = { open = "▐", close = "▌" }


            [status]
            overall = { fg = "${base0D}" }
            sep_left  = { open = "", close = "" }
            sep_right = { open = "", close = "" }

            progress_label = { bold = true }
            progress_normal = { fg = "${base0D}", bg = "${base00}" }
            progress_error = { fg = "${base08}", bg = "${base00}" }

            perm_type = { fg = "${base06}" }
            perm_write = { fg = "${base0E}" }
            perm_exec = { fg = "${base08}" }
            perm_read = { fg = "${base0F}" }
            perm_sep = { fg = "${base0D}" }


            [mode]

            border_set = { as = "plain" }
            normal_main = { bg = "${base0D}", fg = "${base07}", bold = true }
            normal_alt  = { bg = "${base03}", fg = "${base05}" }

            select_main = { bg = "${base06}", fg = "${base01}", bold = true }
            select_alt  = { bg = "${base03}", fg = "${base05}" }

            unset_main = { bg = "${base0E}", fg = "${base17}", bold = true }
            unset_alt  = { bg = "${base03}", fg = "${base05}" }


            [input]
            border_set = { as = "plain" }
            border = { fg = "${base0D}" }
            title = {}
            value = { fg = "${base05}" }
            selected = { reversed = true }

            [tabs]
            active = { fg = "${base00}", bold = true, bg = "${base0D}" }
            inactive = { fg = "${base06}", bg = "${base00}" }
            sep_inner = { open = "", close = "" }

            [cmp]
            border = { fg = "${base0D}", bg = "${base07}" }

            [tasks]
            border = { fg = "${base0D}" }
            title = {}
            hovered = { fg = "${base0F}", underline = true }


            [which]
            border_set = { as = "plain" }
            cols = 3
            mask = { bg = "${base00}" }
            cand = { fg = "${base0D}" }
            rest = { fg = "${base07}" }
            desc = { fg = "${base05}" }
            separator = " ▶ "
            separator_style = { fg = "${base05}" }

            [spot]
            border_set = { as = "plain" }
            border   = { fg = "${base0D}" }
            title    = { fg = "${base0D}" }
            tbl_col  = { fg = "${base05}" }
            tbl_cell = { fg = "${base05}", bg = "${base00}" }


            [help]
            border_set = { as = "plain" }
            on = { fg = "${base05}" }
            run = { fg = "${base05}" }
            hovered = { reversed = true, bold = true }
            footer = { fg = "${base01}", bg = "${base06}" }

            [notify]
            border_set = { as = "plain" }
            title_info = { fg = "${base0E}" }
            title_warn = { fg = "${base0D}" }
            title_error = { fg = "${base08}" }

            [filetype]
            border_set = { as = "plain" }

            rules = [
                { mime = "image/*", fg = "${base15}" },
                { mime = "{audio,video}/*", fg = "${base0A}" },
                { mime = "application/{zip,rar,7z*,tar,gzip,xz,zstd,bzip*,lzma,compress,archive,cpio,arj,xar,ms-cab*}", fg = "${base0F}" },
                { mime = "application/{pdf,doc,rtf}", fg = "${base14}" },
                { mime = "*", is = "orphan", fg = "${base06}", bg = "${base10}" },
                { mime = "application/*exec*", fg = "${base08}" },
                { url = "*", fg = "${base05}" },
                { url = "*/", fg = "${base0D}" },
            ]

            [icon]
            globs = []
              dirs  = [
                { name = ".config", text = "", fg = "${base0D}" },
                { name = ".git", text = "", fg = "${base0D}" },
                { name = ".github", text = "", fg = "${base0D}" },
                { name = ".npm", text = "", fg = "${base0D}" },
                { name = "Desktop", text = "", fg = "${base0D}" },
                { name = "Development", text = "", fg = "${base0B}" }, # Mapped to Green
                { name = "Documents", text = "", fg = "${base0D}" },
                { name = "Downloads", text = "", fg = "${base0D}" },
                { name = "NixOS", text = "", fg = "${base0C}" }, # Mapped to Cyan
                { name = "Library", text = "", fg = "${base0D}" },
                { name = "Movies", text = "", fg = "${base0D}" },
                { name = "Music", text = "", fg = "${base0D}" },
                { name = "Pictures", text = "", fg = "${base0D}" },
                { name = "Public", text = "", fg = "${base0D}" },
                { name = "Videos", text = "", fg = "${base0D}" },
            ]
              conds = [
                # Special files
                { if = "orphan", text = "", fg = "${base08}" }, # Mapped to Red
                { if = "link", text = "", fg = "${base03}" }, # Mapped to Muted Grey
                { if = "block", text = "", fg = "${base0D}" },
                { if = "char", text = "", fg = "${base0D}" },
                { if = "fifo", text = "", fg = "${base0D}" },
                { if = "sock", text = "", fg = "${base0D}" },
                { if = "sticky", text = "", fg = "${base0D}" },
                { if = "dummy", text = "", fg = "${base0D}" },

                # Fallback
                { if = "dir", text = "", fg = "${base0D}" },
                { if = "exec", text = "", fg = "${base08}" }, # Mapped to Red
                { if = "!dir", text = "", fg = "${base05}" }, # Mapped to Default Fg
            ]
          '';
      };
    };
}
