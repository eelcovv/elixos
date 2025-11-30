{
  config,
  pkgs,
  lib,
  ...
}: {
  home.packages = with pkgs; [
    alsa-utils
    pciutils
    mesa-demos
    lshw
    intel-gpu-tools
    inxi
    gptfdisk
    ntfs3g
    fsarchiver
  ];
}
