{pkgs, ...}: let
  # 1. Download the PTGui source tarball
  # 2. Add to store by running `nix store add-path PTGui_13.2.tar.gz'
  # 3. Determine sha by `nix hash file /nix/store/blw8slhy3z8m4c5ms1s799ni8pphf9xk-PTGui_13.2.tar.gz'
  # 4. Use the store path and sha in url and sha256 below
  ptgui_src = builtins.fetchurl {
    url = "file:///nix/store/blw8slhy3z8m4c5ms1s799ni8pphf9xk-PTGui_13.2.tar.gz";
    sha256 = "UXAS06rQ10xIjf5TSqrGNjDhtz61FmVEp/732k9mMp4=";
  };
  ptgui_version = "Pro 13.2";
in {
  home.packages = with pkgs; [
    (callPackage ./ptgui.nix {
      src = ptgui_src;
      version = ptgui_version;
    })
  ];
}
