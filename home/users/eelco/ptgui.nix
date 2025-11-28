{ lib, ... }: {
  # =================================================================
  # To update PTGui to a new version:
  # 1. Download the new tarball (e.g., PTGui_13.3.tar.gz).
  # 2. Get the hash:
  #    nix-prefetch-url file://$HOME/Downloads/PTGui_13.3.tar.gz
  # 3. Update the version and sha256 below.
  # =================================================================
  programs.ptgui = {
    enable = true;
    version = "Pro 13.2";
    sha256 = "sha256-UXAS06rQ10xIjf5TSqrGNjDhtz61FmVEp/732k9mMp4=";
  };
}
