{lib, ...}: {
  # =================================================================
  # To update PTGui to a new version:
  # 1. Download the new tarball (e.g., PTGui_13.3.tar.gz).
  # 2. Get the sha256 hash:
  #    a) If you've already added the tarball to the Nix store (e.g., with `nix-store --add-fixed`),
  #       you can get its hash by running:
  #       nix hash file /nix/store/<hash>-PTGui_13.3.tar.gz
  #       (Replace <hash> with the actual store hash shown by `nix-store`)
  #    b) Alternatively, `nix-prefetch-url` adds the file to the store and prints the hash.
  #       The `nix-prefetch-url` command might output the hash in two formats:
  #       - `sha256-<BASE64_HASH>`: Use this directly.
  #       - `<BASE32_HASH>` (e.g., `0f900d...`): Convert it to the required `sha256-...` format using:
  #         nix hash to-sri --type sha256 <BASE32_HASH_FROM_ABOVE>
  #       (This command may show a deprecation warning, but it works correctly.)
  #       The full command to run:
  #       nix-prefetch-url file://$HOME/Downloads/PTGui_13.3.tar.gz
  #       Copy the final `sha256-...` hash for step 3.
  # 3. Update the version and sha256 below.
  # =================================================================
  programs.ptgui = {
    enable = false;
    version = "Pro 13.3";
    sha256 = "sha256-0vmCW3FIc3e310IcvodM6Kogk2athCkOg5MDPEADIDk=";
  };
}
