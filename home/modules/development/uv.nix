# home/modules/development/uv.nix
{
  pkgs,
  lib,
  config,
  ...
}: let
  # Helper: only include a package if it exists on this nixpkgs
  has = name: builtins.hasAttr name pkgs && pkgs.${name} != null;

  # Create a tiny bin-only shim to avoid lib/pkgconfig collisions in buildEnv
  mkPyShim = name: drv:
    pkgs.writeShellScriptBin name ''
      exec "${drv}/bin/${name}" "$@"
    '';

  shims = lib.flatten [
    (lib.optional (has "python311") (mkPyShim "python3.11" pkgs.python311))
    (lib.optional (has "python313") (mkPyShim "python3.13" pkgs.python313))
    (lib.optional (has "python314") (mkPyShim "python3.14" pkgs.python314))
  ];
in {
  # Put uv and the shims on PATH; avoid adding full extra Pythons to buildEnv.
  home.packages = [pkgs.uv] ++ shims;

  # Force uv to never download interpreters; use system only.
  home.sessionVariables = {
    UV_PYTHON_DOWNLOADS = "never";
    UV_PYTHON_PREFER_SYSTEM = "1";
  };

  # QoL aliases (optional)
  programs.zsh = {
    enable = lib.mkDefault true;
    shellAliases = {
      uv311 = "uv run -p 3.11";
      uv312 = "uv run -p 3.12";
      uv313 = "uv run -p 3.13";
      uv314 = "uv run -p 3.14";
    };
  };
  programs.bash = {
    enable = lib.mkDefault true;
    shellAliases = {
      uv311 = "uv run -p 3.11";
      uv312 = "uv run -p 3.12";
      uv313 = "uv run -p 3.13";
      uv314 = "uv run -p 3.14";
    };
  };
}
