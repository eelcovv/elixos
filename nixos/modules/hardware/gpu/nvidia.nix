{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hardware.nvidia;
in {
  options = {
    hardware.nvidia.enable = lib.mkEnableOption "Enable Nvidia GPU support";

    hardware.nvidia.driver = lib.mkOption {
      type = lib.types.enum ["proprietary" "open"];
      default = "proprietary";
      description = "Which Nvidia driver to use: 'proprietary' or 'open'.";
    };
  };

  config = lib.mkIf cfg.enable {
    hardware.graphics.enable = true;
    services.xserver.videoDrivers = ["nvidia"];

    hardware.nvidia = {
      modesetting.enable = true;
      open = cfg.driver == "open";
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };
}
