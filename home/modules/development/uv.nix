# home/modules/development/uv.nix
{
  pkgs,
  lib,
  config,
  ...
}: let
  # Helper: include a package only if it exists on this nixpkgs
  has = name: builtins.hasAttr name pkgs && pkgs.${name} != null;
  opt = name: lib.optional (has name) pkgs.${name};

  # Put the interpreters you care about here; guarded so older channels won't break
  extraPythons =
    []
    ++ opt "python311"
    ++ opt "python312"
    ++ opt "python313"
    ++ opt "python314"; # available on recent nixpkgs, safely skipped otherwise
in {
  # Ensure uv and multiple CPython interpreters are on PATH for uv to discover.
  home.packages = [pkgs.uv] ++ extraPythons;

  # Absolute ban on uv-managed downloads; force system interpreters.
  # Also keep behavior explicit for shells, scripts, and CI.
  home.sessionVariables = {
    # Never download Python builds; fail if a requested version isn't present.
    UV_PYTHON_DOWNLOADS = "never";
    # Prefer system Pythons (redundant if downloads=never, but harmless and explicit).
    UV_PYTHON_PREFER_SYSTEM = "1";
  };

  # Optional quality-of-life aliases for quickly targeting versions
  # (pure sugar; uv also supports "uv run -p 3.11 ...")
  programs.zsh = {
    enable = lib.mkDefault true;
    shellAliases = {
      "uv311" = "uv run -p 3.11";
      "uv312" = "uv run -p 3.12";
      "uv313" = "uv run -p 3.13";
      "uv314" = "uv run -p 3.14";
    };
  };

  programs.bash = {
    enable = lib.mkDefault true;
    shellAliases = {
      "uv311" = "uv run -p 3.11";
      "uv312" = "uv run -p 3.12";
      "uv313" = "uv run -p 3.13";
      "uv314" = "uv run -p 3.14";
    };
  };
}
