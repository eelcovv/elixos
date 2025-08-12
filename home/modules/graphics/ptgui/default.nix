# ============================================
# 🧩 PTGui Installation Instructions:
#
# 1. Download the PTGui tarball from www.ptgui.com (e.g. PTGui_13.2.tar.gz)
#
# 2. Add the file to the Nix store:
#
#    nix-store --add-fixed sha256 ~/Downloads/PTGui_13.2.tar.gz
# or
#    nix-prefetch-url file://$HOME/Downloads/PTGui_13.2.tar.gz
#
# 3. Determine the sha256 hash of the store path:
#
#    nix hash file /nix/store/blw8slhy3z8m4c5ms1s799ni8pphf9xk-PTGui_13.2.tar.gz
#
# 4. Fill in the correct store path and sha256 hash below in `ptguiStorePath` and `sha256`
#
# ⚠️ Note: Redistribution of PTGui binaries is not allowed — avoid putting this file in public repositories.
# ============================================
{
  pkgs,
  lib,
  ...
}: let
  version = "Pro 13.2";

  # Attempt to require the PTGui tarball; do not fail if it has not been provided.
  _req = builtins.tryEval (pkgs.requireFile {
    name = "PTGui_13.2.tar.gz";
    sha256 = "sha256-UXAS06rQ10xIjf5TSqrGNjDhtz61FmVEp/732k9mMp4=";
    url = "https://www.ptgui.com/"; # informational only
  });

  src =
    if _req.success
    then _req.value
    else (builtins.trace "⚠️ PTGui tarball not found/provided — PTGui will be skipped" null);

  ptgui =
    if src != null
    then pkgs.callPackage ./ptgui.nix {inherit src version;}
    else null;
in {
  # Only add PTGui to home.packages if 'src' is available
  home.packages = lib.optionals (ptgui != null) [ptgui];
}
