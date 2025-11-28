{ lib, ... }: {
  # =================================================================
  # To update PTGui to a new version:
  # 1. Download the new tarball (e.g., PTGui_13.3.tar.gz).
  # 2. Get the sha256 hash:
  #    a) If you've already added the tarball to the Nix store (e.g., with `nix-store --add-fixed`),
  #       you can get its hash by running:
  #       nix hash file /nix/store/<hash>-PTGui_13.3.tar.gz
  #       (Replace <hash> with the actual store hash shown by `nix-store`)
  #    b) Alternatively, `nix-prefetch-url` adds the file to the store and prints the hash:
  #       nix-prefetch-url file://$HOME/Downloads/PTGui_13.3.tar.gz
  #       Copy the sha256 hash from its output.
  # 3. Update the version and sha256 below.
  # =================================================================
  programs.ptgui = {
    enable = true;
    version = "Pro 13.2";
    sha256 = "sha256-UXAS06rQ10xIjf5TSqrGNjDhtz61FmVEp/732k9mMp4=";
  };
}
