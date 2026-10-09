{
  exo.mods.desktop = {
    forte.hyprland.lua.settings = # lua
      ''
        -- persist workspaces 1 to 5
        for i = 1, 6 do
          hl.workspace_rule({ workspace = tostring(i), persistent = true })
        end

        -- Switch workspaces with SUPER + [0-9]
        -- Move active window to a workspace with SUPER + SHIFT + [0-9]
        for i = 1, 10 do
          local key = i % 10 -- 10 maps to key 0
          hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = i }))
          hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
        end

        -- special workspace (scratchpad)
        hl.bind("SUPER + S", hl.dsp.workspace.toggle_special("magic"))
        hl.bind("SUPER + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

        -- dynamically calculate the scrolling_width for aspect ratios of 16:9 and 21:9
        local gaps_out = 8
        local gaps_in = 4
        local border_size = 5

        local PIXEL_BIAS = 0
        local BPP_PLUGIN = "borders-plus-plus"
        local BPP_CFG = "plugin:borders_plus_plus:"

        hl.config({ general = { gaps_out = gaps_out, gaps_in = gaps_in, border_size = border_size } })

        local function isPluginLoaded(name)
          for _, p in ipairs(hl.get_loaded_plugins()) do
            if p.name == name then
              return true
            end
          end
          return false
        end

        -- sum of borders-plus-plus reserved px per side, read live from config
        local function bpp_extra_border()
          local add = hl.get_config(BPP_CFG .. "add_borders") or 0
          local extra = 0
          for i = 1, add do
            local size = hl.get_config(BPP_CFG .. "border_size_" .. i)
            if not size then
              size = (i == 1) and hl.get_config("general:border_size") or hl.get_config(BPP_CFG .. "border_size_" .. (i - 1))
            end
            extra = extra + (size or 0)
          end
          return extra
        end

        local w169, w219

        local function apply_widths()
          local monitor = hl.get_active_monitor()
          if not monitor then
            return
          end

          -- account for plugin borders only while the plugin is actually loaded
          local bpp = isPluginLoaded(BPP_PLUGIN)
          local extra_border = bpp and bpp_extra_border() or 0
          local bias = bpp and PIXEL_BIAS or 0
          local total_border = border_size + extra_border

          local W, H = monitor.width, monitor.height
          local res = monitor.reserved or { top = 0, bottom = 0, left = 0, right = 0 }

          local usable_w = W - res.left - res.right - 2 * gaps_out
          local usable_h = H - res.top - res.bottom - 2 * gaps_out

          local inner_h = usable_h - 2 * total_border

          local function width_for(ratio, gaps_in_sides)
            local content_w = math.floor(ratio * inner_h + 0.5)
            local col_px = content_w + 2 * total_border + gaps_in_sides * gaps_in + bias
            return col_px / usable_w
          end

          w169 = width_for(16 / 9, 2)
          w219 = width_for(21 / 9, 2)

          hl.config({
            scrolling = {
              column_width = w169,
            },
          })

          hl.workspace_rule {
            workspace = "1",
            layout_opts = {
              explicit_column_widths = "0.333,0.5,0.667," .. w169 .. "," .. w219
            }
          }

          hl.workspace_rule {
            workspace = "2",
            layout_opts = {
              explicit_column_widths = "0.333,0.5,0.667," .. w169 .. "," .. w219
            }
          }

          hl.workspace_rule {
            workspace = "3",
            layout_opts = {
              explicit_column_widths = "0.333,0.5," .. w169
            }
          }

          hl.workspace_rule {
            workspace = "4",
            layout_opts = {
              explicit_column_widths = "0.333,0.5," .. w169
            }
          }

          hl.workspace_rule {
            workspace = "6",
            layout_opts = {
              explicit_column_widths = "0.5," .. w169 .. "," .. w219
            }
          }

          hl.workspace_rule {
            workspace = "special:magic",
            layout_opts = {
              explicit_column_widths = "0.5," .. w169 .. "," .. w219
            }
          }
        end

        local function refresh()
          hl.timer(apply_widths, { timeout = 200, type = "oneshot" })
        end

        apply_widths()

        hl.on("layer.opened", refresh)
        hl.on("layer.closed", refresh)
        hl.on("config.reloaded", refresh)

        hl.workspace_rule {
          workspace = "5",
          layout_opts = {
            explicit_column_widths = "0.333,0.5"
          }
        }
      '';
  };
}
