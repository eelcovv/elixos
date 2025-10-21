# home/modules/development/default.nix
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
    ./uv.nix
    ./vscode.nix
    ./rootless-podman-storage.nix
  ];

  pypi = {
    enable = true;
    davelab = {
      enable = true;
      repository = "https://pypi.davelab.eu";
      auth.mode = "basic";
    };
    testpypi = {
      enable = true;
    };
  };

  sops.secrets."pypi_token_testpypi" = {
    path = "${config.xdg.runDir}/secrets/pypi_token_testpypi";
    sopsFile = ../../../nixos/secrets/pypi/testpypi_token_eelco.yaml;
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

    # Ensure 'systemctl' is available for HM activation scripts
    systemd
  ];
}
