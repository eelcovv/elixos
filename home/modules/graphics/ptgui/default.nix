# ============================================
# 🧩 PTGui Installation Instructions:
#
# This module is configured via the `programs.ptgui.*` options.
#
# To use a new version of PTGui:
#
# 1. Download the PTGui tarball from www.ptgui.com (e.g., PTGui_13.3.tar.gz).
#
# 2. Add the file to the Nix store and get its sha256 hash using `nix-prefetch-url`:
#
#    nix-prefetch-url file://$HOME/Downloads/PTGui_13.3.tar.gz
#
# 3. In your configuration, set the `programs.ptgui` options. For example:
#
#    programs.ptgui = {
#      enable = true;
#      version = "Pro 13.3";
#      sha256 = "sha256-THE_SHA256_HASH_FROM_STEP_2";
#    };
#
#    The `version` string is used to generate the expected tarball name, e.g.,
#    "Pro 13.3" becomes "PTGui_13.3.tar.gz".
#
# 4. Rebuild your configuration.
#
# ⚠️ Note: Redistribution of PTGui binaries is not allowed — avoid putting this
# file in public repositories.
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
