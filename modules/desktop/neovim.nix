{
  tack.inputs.nito = {
    url = "gh:onelocked/nito";
    group = "general";
  };
  exo.mods.neovim = {
    forte.neovim.enable = true;
    forte.persist = {
      home.directories = [
        ".local/share/nvim" # data directory
        ".local/state/nvim" # persistent session info
        ".supermaven"
        ".local/share/supermaven"
        ".local/share/firenvim"
      ];
    };
  };
  exo.skeleton =
    {
      lib,
      inputs',
      config,
      theme,
      pkgs,
      ...
    }:
    let
      cfg = config.forte.neovim;
      nvimFindScript =
        pkgs.writeText "nvim-find.lua" # lua
          ''
            local target = vim.uv.fs_realpath(arg[1]) or vim.fn.fnamemodify(arg[1], ":p")
            local line = tonumber(arg[2]) or 0

            local remote_code = [==[
              local target, line = ...
              local function real(p)
                return (vim.uv.fs_realpath(p)) or vim.fn.fnamemodify(p, ":p")
              end
              for _, b in ipairs(vim.api.nvim_list_bufs()) do
                local name = vim.api.nvim_buf_get_name(b)
                if name ~= "" and vim.bo[b].buflisted and real(name) == target then
                  local wins = vim.fn.win_findbuf(b)
                  if #wins > 0 then
                    vim.api.nvim_set_current_win(wins[1])
                  else
                    vim.api.nvim_set_current_buf(b)
                  end
                  if line > 0 then
                    pcall(vim.api.nvim_win_set_cursor, 0, { line, 0 })
                    vim.cmd("normal! zz")
                  end
                  return vim.env.KITTY_WINDOW_ID or false
                end
              end
              return false
            ]==]

            local uid = vim.fn.system("id -u"):gsub("%s+", "")
            local sockets = vim.fn.glob("/run/user/" .. uid .. "/nvim.*.0", true, true)
            for _, socket in ipairs(sockets) do
              if socket ~= vim.v.servername then
                local ok, chan = pcall(vim.fn.sockconnect, "pipe", socket, { rpc = true })
                if ok and chan > 0 then
                  local req_ok, result = pcall(vim.rpcrequest, chan, "nvim_exec_lua", remote_code, { target, line })
                  pcall(vim.fn.chanclose, chan)
                  if req_ok and result and result ~= vim.NIL then
                    io.write(tostring(result))
                    os.exit(0)
                  end
                end
              end
            end
            os.exit(1)
          '';

      nvimFocus = pkgs.writeShellApplication {
        name = "nvim-focus";
        runtimeInputs = [
          pkgs.kitty
          pkgs.coreutils
        ];
        text = ''
          file=""
          line=0
          if [ "$#" -eq 1 ]; then
            file=$1
          elif [ "$#" -eq 2 ] && [[ "$1" == +[0-9]* ]]; then
            line=''${1#+}
            file=$2
          fi

          if [ -n "$file" ] && [ -f "$file" ]; then
            if id=$(${pkgs.neovim}/bin/nvim --clean -l ${nvimFindScript} "$file" "$line" 2>/dev/null) && [ -n "$id" ]; then
              if kitty @ focus-window -m "id:$id" >/dev/null 2>&1; then
                exit 0
              fi
            fi
          fi

          exec nvim "$@"
        '';
      };
    in
    {
      config = lib.mkIf cfg.enable {
        hj.packages = [
          cfg.package
          nvimFocus
        ];
        environment.sessionVariables = {
          EDITOR = "nvim-focus";
          VISUAL = "nvim-focus";
        };
        forte.lazygit.settings = {
          os =
            let
              lazygitEdit = pkgs.writeShellApplication {
                name = "lazygit-edit";
                runtimeInputs = [ pkgs.coreutils ];
                text = ''
                  file=$(realpath -m -- "$1")
                  line=''${2:-0}

                  if [ -z "''${NVIM:-}" ]; then
                    if [ "$line" -gt 0 ]; then
                      exec nvim-focus "+$line" "$file"
                    fi
                    exec nvim-focus "$file"
                  fi

                  q="'"
                  esc=''${file//$q/$q$q}

                  nvim --server "$NVIM" --remote-send '<C-\><C-n><cmd>close<cr>'
                  nvim --server "$NVIM" --remote-expr "v:lua.LazygitEdit('$esc', $line)" >/dev/null
                '';
              };
            in
            {
              editInTerminal = true;
              edit = "${lazygitEdit}/bin/lazygit-edit {{filename}}";
              editAtLine = "${lazygitEdit}/bin/lazygit-edit {{filename}} {{line}}";
            };
        };
      };
      options.forte.neovim = {
        enable = lib.mkEnableOption "neovim";
        package = lib.mkOption {
          type = lib.types.package;
          default = inputs'.nito.packages.${theme};
          defaultText = "default package for neovim";
        };
      };
    };

  exo.mods.desktop =
    { config, lib, ... }:
    let
      cfg = config.forte.neovim;
      mimeType = [
        "text/english"
        "text/plain"
        "text/x-makefile"
        "text/x-c++hdr"
        "text/x-c++src"
        "text/x-chdr"
        "text/x-csrc"
        "text/x-java"
        "text/x-moc"
        "text/x-pascal"
        "text/x-tcl"
        "text/x-tex"
        "application/x-shellscript"
        "text/x-c"
        "text/x-c++"
      ];
    in
    {
      config = lib.mkIf cfg.enable {
        forte.xdg.desktopEntries = {
          "nvim" = {
            name = "Neovim";
            noDisplay = true;
            genericName = "Text Editor";
            comment = "Edit text files";
            exec = "nvim %F";
            terminal = true;
            type = "Application";
            icon = "nvim";
            startupNotify = false;
            inherit mimeType;
            settings = {
              TryExec = "nvim";
            };
          };
        };
        xdg.mime.defaultApplications =
          mimeType |> map (mime: lib.nameValuePair mime [ "nvim.desktop" ]) |> lib.listToAttrs;
      };
    };
}
