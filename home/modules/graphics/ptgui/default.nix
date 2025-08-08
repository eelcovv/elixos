{pkgs, ...}: let
  ptgui_src = builtins.fetchurl {
    url = "file:///nix/store/25hxfzmwkc8nv1k6rhcm3x2ffhz7lbx0-PTGui_13.0.tar.gz";
    sha256 = "1mvhqbr348np3in0n7wb98sbxgyrajl25rflys3k2pcd633k46ww";
  };
  ptgui_version = "Pro 13.0";
in {
  home.packages = with pkgs; [
    (callPackage ./ptgui.nix {
      src = /var/lib/ptgui/PTGui_Pro_13.2.tar.gz;
      version = "Pro 13.2";
    })
  ];
}
