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

  pythonRtLibs.enable = true;
  pythonRtLibs.withQtDev = false;
  pythonRtLibs.withWayland = true;
  pythonRtLibs.withX11 = true;
  pythonRtLibs.useLdLibraryPath = true; #  Put on False if you use Nix-LD
  # enable PyPI integration (writes ~/.pypirc from /run/secrets/*)
  pypi = {
    enable = true;
    davelab = {
      enable = true;
      repository = "https://pypi.davelab.eu";
      auth.mode = "basic";
    };
  };

  home.packages = with pkgs; [
    alejandra
    direnv
    gcc
    nodejs
    gnumake
    htop
    tree
    wget
  ];
}
