{
  exo.core =
    {
      pkgs,
      config,
      constants,
      ...
    }:
    {
      sops.secrets.email.owner = constants.username;
      sops.templates."git-email" = {
        owner = constants.username;
        content = ''
          [user]
            email = ${config.sops.placeholder."email"}
        '';
      };
      programs.git = {
        enable = true;
        config = {
          include = {
            path = config.sops.templates."git-email".path;
          };
          user = {
            name = "onelocked";
          };
          interactive = {
            diffFilter = "delta --color-only";
          };
          core = {
            editor = "$EDITOR";
            pager = "delta";
            excludesfile = "${pkgs.writeText "gitignore-global" ''
              .envrc
              .direnv
              result*
            ''}";
          };
          delta = {
            navigate = true;
            light = true;
            line-numbers = true;
            hyperlinks = true;
          };
          merge = {
            conflictStyle = "zdiff3";
          };
          diff = {
            colorMoved = "default";
          };
          pager = {
            diff = "diffnav";
            show = "diffnav";
            log = "diffnav";
          };
          init.defaultBranch = "main";
          advice.objectNameWarning = false;
          pull.rebase = true;
          safe.directory = "/tmp";
        };
      };
    };
}
