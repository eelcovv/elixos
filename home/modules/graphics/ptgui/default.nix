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
  config,
  pkgs,
  lib,
  ...
}: {
  options.programs.ptgui = {
    enable = lib.mkEnableOption "PTGui panorama stitcher";
    version = lib.mkOption {
      type = lib.types.str;
      default = "Pro 13.2";
      description = "PTGui version to use.";
    };
    tarballPath = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to the PTGui tarball in the Nix store.";
    };
    sha256 = lib.mkOption {
      type = lib.types.str;
      default = "sha256-UXAS06rQ10xIjf5TSqrGNjDhtz61FmVEp/732k9mMp4=";
      description = "SHA256 hash of the PTGui tarball.";
    };
  };

  config = lib.mkIf config.programs.ptgui.enable (
    let
      cfg = config.programs.ptgui;
      version = cfg.version;
      tarballName = "PTGui_${lib.replaceStrings [" " "Pro "] ["_" ""] version}.tar.gz";

      # Attempt to require the PTGui tarball; do not fail if it has not been provided.
      _req = builtins.tryEval (
        if cfg.tarballPath != null then
          pkgs.fetchurl {
            url = "file://${cfg.tarballPath}";
            sha256 = cfg.sha256;
          }
        else
          pkgs.requireFile {
            name = tarballName;
            sha256 = cfg.sha256;
            url = "https://www.ptgui.com/"; # informational only
          }
      );

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
  );
}
