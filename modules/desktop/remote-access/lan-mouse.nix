{
  tack.inputs.lan-mouse = {
    url = "gh:feschber/lan-mouse";
    type = "fetch";
    group = "desktop";
  };
  exo.mods.remote-access = {
    forte.lan-mouse = {
      enable = true;
      openFirewall = true;
      settings = {
        authorized_fingerprints = {
          "50:96:77:ad:06:2c:ef:52:71:8a:1d:92:1c:56:e7:a4:95:3b:b0:6c:9f:cd:b2:66:b4:01:a2:d6:24:d0:cd:a0" =
            "mini-pc2";
        };
      };
    };
  };
  exo.skeleton =
    {
      self',
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.forte.lan-mouse;
      tomlFormat = pkgs.formats.toml { };
    in
    {
      config =
        lib.mkIf cfg.enable
        <| lib.mkMerge [
          {
            hj.systemd.services.lan-mouse = {
              description = "Lan Mouse Daemon";
              wantedBy = [ "graphical-session.target" ];
              partOf = [ "graphical-session.target" ];
              after = [ "graphical-session.target" ];
              serviceConfig = {
                Type = "simple";
                ExecStart = "${lib.getExe cfg.package} --config ${tomlFormat.generate "config.toml" cfg.settings} --capture-backend dummy daemon";
                Restart = "on-failure";
                RestartSec = 1;
                TimeoutStopSec = 10;
              };
            };
          }
          (lib.mkIf cfg.openFirewall {
            networking.firewall.allowedUDPPorts = [ 4242 ];
          })
        ];
      options.forte.lan-mouse = {
        enable = lib.mkEnableOption "lan-mouse";
        package = lib.mkOption {
          type = lib.types.package;
          default = self'.packages.lan-mouse;
          description = "The package to use for lan-mouse";
        };
        settings = lib.mkOption {
          inherit (tomlFormat) type;
          default = { };
          description = ''
            Optional configuration written to {file}`$XDG_CONFIG_HOME/lan-mouse/config.toml`.

            See <https://github.com/feschber/lan-mouse/> for
            available options and documentation.
          '';
        };
        openFirewall = lib.mkEnableOption "lan-mouse";
      };
    };
  perSystem =
    { pkgs, inputs, ... }:
    {
      remotePackages.lan-mouse = pkgs.rustPlatform.buildRustPackage (finalAttrs: {
        pname = inputs._meta.lan-mouse.repo;
        version = inputs._meta.lan-mouse.rev;
        src = inputs.lan-mouse;

        doCheck = false;
        buildNoDefaultFeatures = true;

        buildFeatures = [
          "layer_shell_capture"
          "wlroots_emulation"
        ];

        cargoLock.lockFile = finalAttrs.src + "/Cargo.lock";

        meta.mainProgram = "lan-mouse";

        patches = [
          (pkgs.writeText "disable-side-buttons" # rust
            ''
              diff --git a/src/capture.rs b/src/capture.rs
              index 8f739bd..f37803c 100644
              --- a/src/capture.rs
              +++ b/src/capture.rs
              @@ -322,6 +322,14 @@ impl CaptureTask {
                       let (handle, event) = event;
                       log::trace!("({handle}): {event:?}");

              +        if let CaptureEvent::Input(Event::Pointer(input_event::PointerEvent::Button {
              +            button: input_event::BTN_BACK | input_event::BTN_FORWARD,
              +            ..
              +        })) = event
              +        {
              +            return Ok(());
              +        }
              +
                       if capture.keys_pressed(&self.release_bind.borrow()) {
                           log::info!("releasing capture: release-bind pressed");
                           return self.release_capture(capture).await;
              diff --git a/src/emulation.rs b/src/emulation.rs
              index 923bf99..63eb224 100644
              --- a/src/emulation.rs
              +++ b/src/emulation.rs
              @@ -278,6 +278,14 @@ impl EmulationProxy {
                   }

                   fn consume(&self, event: Event, addr: SocketAddr) {
              +        if let Event::Pointer(input_event::PointerEvent::Button {
              +            button: input_event::BTN_BACK | input_event::BTN_FORWARD,
              +            ..
              +        }) = event
              +        {
              +            return;
              +        }
              +
                       // ignore events if emulation is currently disabled
                       if self.emulation_active.get() {
                           self.request_tx
            ''
          )
        ];
      });
    };
}
