# home/modules/python.nix
{
  pkgs,
  lib,
  ...
}: let
  # Choose which interpreters you want installed system-wide.
  # Keep 'Full' for at least one version if you often need headers/Tk.
  modernPythons =
    [
      pkgs.python310
      pkgs.python311
      pkgs.python312Full
    ]
    # Only add these if your nixpkgs actually has them:
    ++ (lib.optional (pkgs ? python313) pkgs.python313)
    ++ (lib.optional (pkgs ? python314) pkgs.python314);
in {
  # System-wide interpreters available on PATH for uv to use with --system.
  home.packages = modernPythons;

  # TIP (optional, not required):
  # If you also want Python 3.8/3.9, expose them via an extra nixpkgs input
  # in your flake and import them in a separate module, then append here.
  #
  # For example (in a separate legacy-python.nix):
  #   let
  #     legacy38 = (import inputs.nixpkgs-23_05 { system = pkgs.system; }).python38;
  #     legacy39 = (import inputs.nixpkgs-23_11 { system = pkgs.system; }).python39;
  #   in { home.packages = [ legacy38 legacy39 ]; }
  #
  # Then import both modules in your Home-Manager config.
}
