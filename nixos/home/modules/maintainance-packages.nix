{
  config,
  pkgs,
  lib,
  ...
}: {
  home.packages = with pkgs; [
    pciutils
    mesa-utils
    nvidia-smi
    nvtop
    lshw
    intel-gpu-tools
    inxi
  ];
}
