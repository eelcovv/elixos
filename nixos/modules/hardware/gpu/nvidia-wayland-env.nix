{ lib, config, ... }:

lib.mkIf (config.hardware.nvidia.modesetting.enable && config.programs.hyprland.enable) {
  environment.sessionVariables = {
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    __GL_VRR_ALLOWED = "1";
    WLR_NO_HARDWARE_CURSORS = "1";
  };
}
