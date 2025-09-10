{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./docker.nix
    ./direnv.nix
    ./git-default.nix
    ./pycharm.nix
    ./pypi.nix
    ./python.nix
    ./python-devtools.nix
    ./python-rt-libs.nix
    ./uv.nix
    ./vscode.nix
    ./rootless-podman-storage.nix
  ];

  # PyPI integratie (schrijft ~/.pypirc vanuit /run/secrets/*)
  pypi = {
    enable = true;
    davelab = {
      enable = true;
      repository = "https://pypi.davelab.eu";
      auth.mode = "basic";
    };
  };

  # Alleen tools, geen compilers (toolchains in devShell houden is schoner)
  home.packages = with pkgs; [
    alejandra
    direnv
    nodejs
    gnumake
    htop
    tree
    wget
  ];

  # Python runtime libs (zonder LD_LIBRARY_PATH in HM)
  pythonRtLibs = {
    enable = true;
    withQtDev = false; # PySide6 via uv
    withWayland = true;
    withX11 = true;
  };
}
