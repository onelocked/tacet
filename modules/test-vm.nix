{
  exo.core = {
    virtualisation.vmVariant = {
      virtualisation = {
        memorySize = 4096;
        cores = 4;
        qemu.options = [
          "-device virtio-vga-gl"
          "-display gtk,gl=on,grab-on-hover=on"
        ];
      };
      environment.sessionVariables = {
        LIBGL_ALWAYS_SOFTWARE = "1";
        WLR_RENDERER_ALLOW_SOFTWARE = "1";
        WLR_NO_HARDWARE_CURSORS = "1";
      };
    };
  };
}
