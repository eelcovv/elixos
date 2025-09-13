# home/modules/development/default.nix
{
  config,
  pkgs,
  lib,
  ...
}: {
  # Keep dev tooling modules; remove only heavy runtime stacks from HM
  imports = [
    ./docker.nix
    ./direnv.nix
    ./git-default.nix
    ./pycharm.nix
    ./pypi.nix
    ./python.nix
    ./python-devtools.nix
    ./uv.nix
    ./vscode.nix
    ./rootless-podman-storage.nix
  ];

  # PyPI integration (writes ~/.pypirc from /run/secrets/*)
  pypi = {
    enable = true;
    davelab = {
      enable = true;
      repository = "https://pypi.davelab.eu";
      auth.mode = "basic";
    };
  };

  # Global CLI tools only (no compilers/runtimes here)
  home.packages = with pkgs; [
    alejandra
    direnv
    nodejs
    gnumake
    htop
    tree
    wget
  ];
}
