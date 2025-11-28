# ============================================
# 🧩 PTGui Installation Instructions:
#
# 1. Download the PTGui tarball from www.ptgui.com (e.g. PTGui_13.3.tar.gz)
#
# 2. Place the downloaded `PTGui_13.3.tar.gz` file in this directory.
#
# 3. The configuration will automatically use it.
#
# ⚠️ Note: Redistribution of PTGui binaries is not allowed.
#    The tarball is ignored by .gitignore and should not be committed.
# ============================================
{
  config,
  pkgs,
  lib,
  ptguiTarballPath, # Path to the PTGui tarball
  ptguiVersion ? "Pro 13.3", # Version of PTGui
  ptguiSha256 ? "sha256-79cd4f3ef4cd3b8765340307d7dbc4ca351f6be70382c07af3cceea8a3f910ff", # SHA256 hash
  ...
}: {
  options.programs.ptgui.enable = lib.mkEnableOption "PTGui panorama stitcher";

  config = lib.mkIf config.programs.ptgui.enable (
    let
      # Determine the source for PTGui
      src =
        if ptguiTarballPath != null
        then pkgs.fetchurl {
          url = "file://${ptguiTarballPath}";
          sha256 = ptguiSha256;
        }
        else
          throw ''
            PTGui tarball path not specified!

            To enable PTGui, you must provide the path to the downloaded tarball.
            1. Download PTGui_13.3.tar.gz from www.ptgui.com
            2. Add it to your Nix store:
               nix-store --add-fixed sha256 ~/Downloads/PTGui_13.3.tar.gz
               (or use nix-prefetch-url file://$HOME/Downloads/PTGui_13.3.tar.gz)
            3. Use the resulting store path to set 'ptguiTarballPath' in your Home Manager configuration.
               Example in flake.nix:
               { _module.args = { inherit inputs self; userModulesPath = ./home/users; ptguiTarballPath = "/nix/store/...-PTGui_13.3.tar.gz"; }; }
          '';

      ptgui = pkgs.callPackage ./ptgui.nix {
        inherit src;
        version = ptguiVersion;
      };
    in {
      home.packages = [ptgui];
    }
  );
}
