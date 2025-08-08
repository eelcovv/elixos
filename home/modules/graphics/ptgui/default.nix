{pkgs, ...}: let
  # Add the PTGui package to the store by Downloading the source tarball and running:
  # nix store add-path PTGui_13.2.tar.gz
  ptgui_src = /nix/store/25hxfzmwkc8nv1k6rhcm3x2ffhz7lbx0-PTGui_Pro_13.2.tar.gz;
  ptgui_version = "Pro 13.2";
in {
  home.packages = with pkgs; [
    (callPackage ./ptgui.nix {
      src = ptgui_src;
      version = ptgui_version;
    })
  ];
}
