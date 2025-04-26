{ config, pkgs, lib, ... }:


let
  hostSpecificKeys = {
    "tongfang" = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC3+DBjLHGlQinS0+qeC5JgFakaPFc+b+btlZABO7ZX6 eelco@tongfang"
    ];
    "tongfang-vm" = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC3+DBjLHGlQinS0+qeC5JgFakaPFc+b+btlZABO7ZX6 eelco@vm"
    ];
  };
  keys = hostSpecificKeys.${config.home.hostname} or [];
in
{
  imports = [
    ../modules/home/common-packages.nix
  ];

  home-manager.users.eelco = {
    home.username = "eelco";
    home.homeDirectory = "/home/eelco";
    home.stateVersion = "24.11";

    # SSH authorized keys
    programs.ssh = {
      enable = true;
      authorizedKeys.keys = keys;
    };

    # Shell (zsh) config
    programs.zsh = {
      enable = true;
      ohMyZsh.enable = true;
      ohMyZsh.theme = "agnoster"; # or any other theme you like
    };

    # Git config
    programs.git = {
      enable = true;
      userName = "Eelco van Vliet";
      userEmail = "eelco@example.com"; # change to your real email
      extraConfig = {
        core.editor = "vim";
      };
    };

    # Install some basic packages
    home.packages = with pkgs; [
      neovim
      git
      htop
      wget
      curl
      tree
    ];
  };
}
