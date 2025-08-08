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
    hardware.nvidia.useOpenDriver = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Use Nvidia's open source kernel module instead of proprietary driver.";
    };
  };

  config = lib.mkIf cfg.enable {
    hardware.graphics.enable = true;
    services.xserver.videoDrivers = ["nvidia"];

    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      open = cfg.useOpenDriver;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };
}
