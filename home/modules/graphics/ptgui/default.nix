{pkgs, ...}: let
  # ============================================
  # 🧩 PTGui Installation Instructions:
  #
  # 1. Download the PTGui tarball from www.ptgui.com (e.g. PTGui_13.2.tar.gz)
  #
  # 2. Add the file to the Nix store:
  #    nix store add-path ~/Downloads/PTGui_13.2.tar.gz
  #
  # 3. Determine the sha256 hash of the store path:
  #    nix hash file /nix/store/blw8slhy3z8m4c5ms1s799ni8pphf9xk-PTGui_13.2.tar.gz
  #
  # 4. Fill in the correct store path and sha256 hash below in `ptguiStorePath` and `sha256`
  #
  # ⚠️ Note: Redistribution of PTGui binaries is not allowed — avoid putting this file in public repositories.
  # ============================================
  ptguiStorePath = "/nix/store/blw8slhy3z8m4c5ms1s799ni8pphf9xk-PTGui_13.2.tar.gz";

  ptguiEnabled = builtins.pathExists ptguiStorePath;

  _ =
    if !ptguiEnabled
    then
      builtins.trace "⚠️  PTGui tarball not found in store — PTGui will not be installed"
      null
    else null;

  ptgui_src =
    if ptguiEnabled
    then
      builtins.fetchurl {
        url = "file://${ptguiStorePath}";
        sha256 = "UXAS06rQ10xIjf5TSqrGNjDhtz61FmVEp/732k9mMp4=";
      }
    else null;

  ptgui_version = "Pro 13.2";
in {
  home.packages = with pkgs;
    [
      # Add other packages here if needed
    ]
    ++ (
      if ptguiEnabled
      then [
        (callPackage ./ptgui.nix {
          src = ptgui_src;
          version = ptgui_version;
        })
      ]
      else []
    );
}
