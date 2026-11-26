{
  tack.inputs.mddog = {
    url = "gh:qu8n/mddog";
    group = "cli";
    type = "fetch";
  };
  perSystem = { pkgs, inputs, ... }: {
    remotePackages.mddog = pkgs.rustPlatform.buildRustPackage (finalAttrs: {
      pname = inputs._meta.mddog.repo;
      version = inputs._meta.mddog.rev;
      src = inputs.mddog;
      cargoLock.lockFile = finalAttrs.src + "/Cargo.lock";
      doCheck = false;
    });
  };

  exo.core =
    {
      self',
      pkgs,
      config,
      lib,
      ...
    }:
    let
      mddSplit = pkgs.writeShellApplication {
        name = "yazi-mdd-split";
        runtimeInputs = [
          config.forte.kitty.package
          self'.packages.yazi
          pkgs.util-linux
          self'.packages.mddog
        ];
        text = ''
          if [ -z "''${MDD_SPLIT_DETACHED:-}" ]; then
            MDD_SPLIT_DETACHED=1 exec setsid -f "$0" "$@"
          fi
          exec </dev/null >/dev/null 2>&1
          win="''${KITTY_WINDOW_ID:?not running inside kitty}"
          [ -S /tmp/kitty ] && sock="unix:/tmp/kitty" || sock="''${KITTY_LISTEN_ON:?no kitty remote control socket}"
          k() { kitty @ --to "$sock" "$@"; }

          want="/tmp/yazi-mdd-$win.want"

          close() { k close-window --match="var:yazi_mdd=$win" >/dev/null 2>&1 || true; }

          case "''${1:-}" in
            open)
              # Give the cursor 200ms to keep moving: the plugin rewrites the wanted
              # path on every hover, so a wait that ends on another file does nothing.
              sleep 0.2
              [ "$(cat "$want" 2>/dev/null)" = "$2" ] || exit 0

              exec 9>"/tmp/yazi-mdd-$win.lock"
              flock -w 2 9
              [ "$(cat "$want" 2>/dev/null)" = "$2" ] || exit 0

              close
              # Backgrounded: the launch call does not return in this context, and the
              # preview has to move at the same time as the split.
              k launch \
                --next-to="id:$win" \
                --location=vsplit \
                --keep-focus \
                --var "yazi_mdd=$win" \
                -- mdd "$2" &
              ya emit plugin mdd-split preview-hide
              ;;
            close)
              close
              ya emit plugin mdd-split preview-show
              ;;
            *) echo "usage: $0 open <file> | close" >&2; exit 2 ;;
          esac
        '';
      };
    in
    {
      hj.packages = [
        self'.packages.mddog
        mddSplit
      ];
      forte.yazi = {
        plugins = lib.mkAfter {
          mdd-split = pkgs.yaziPlugins.mkYaziPlugin {
            pname = "mdd-split";
            version = "local";
            src =
              pkgs.writeTextDir "main.lua" # lua
                ''
                  local M = {}

                  local current = nil
                  local want = "/tmp/yazi-mdd-" .. (os.getenv("KITTY_WINDOW_ID") or "0") .. ".want"

                  local hovered = ya.sync(function()
                    local h = cx.active.current.hovered
                    return h and tostring(h.url) or nil
                  end)

                  local preview_hidden = ya.sync(function() return rt.mgr.ratio[3] == 0 end)

                  local function markdown(url)
                    return url:match("%.md$") or url:match("%.markdown$") or url:match("%.mdx$")
                  end

                  local function preview(visible)
                    if preview_hidden() == visible then
                      ya.emit("plugin", { "toggle-pane", "min-preview" })
                    end
                  end

                  function M:setup()
                    ps.sub("hover", function()
                      local url = hovered()
                      if url and not markdown(url) then url = nil end
                      if url == current then return end
                      current = url
                      local f = io.open(want, "w")
                      if f then
                        f:write(url or "")
                        f:close()
                      end

                      ya.async(function() Command("yazi-mdd-split"):arg(url and { "open", url } or { "close" }):spawn() end)
                    end)
                  end

                  -- Called by the helper, so the pane moves with the split instead of
                  -- 200ms before it.
                  function M:entry(job)
                    local arg = (job.args or {})[1] or ""
                    local hidden = arg == "preview-hide"
                    if hidden ~= preview_hidden() then
                      ya.emit("plugin", { "toggle-pane", "min-preview" })
                    end
                  end

                  return M
                '';
          };
        };
        initLua =
          lib.mkAfter # lua
            ''
              require("mdd-split"):setup()
            '';
      };
    };
}
