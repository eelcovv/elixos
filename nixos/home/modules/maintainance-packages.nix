{
  config,
  pkgs,
  lib,
  ...
}: {
  home.packages = with pkgs; [
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
