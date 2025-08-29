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
    htop
    wget
    tree
    direnv
    gnumake
  ];
}
