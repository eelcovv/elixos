{ config, pkgs, lib, ... }:

let
  # Always familiar keys for all hosts
  trustedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC3+DBjLHGlQinS0+qeC5JgFakaPFc+b+btlZABO7ZX6 eelco@tongfang"
  ];

  # Extra keys per specific host
  hostSpecificKeys = {
    tongfang = [];
    generic-vm = [];
  };

  # The full list: TrustedKeys + Possible host-specific
  keys = trustedKeys ++ (hostSpecificKeys.${config.networking.hostName} or []);
in
{
  home-manager.users.eelco = {
    home.username = "eelco";
    home.homeDirectory = "/home/eelco";
    home.stateVersion = "24.11";

    # Correct way to define authorized keys in Home Manager
    programs.ssh = {
      enable = true;
    };

    # Shell (zsh) config
    programs.zsh = {
      enable = true;
    };

    # Git config
    programs.git = {
      enable = true;
      userName = "Eelco van Vliet";
      userEmail = "eelcovv@gmail.com";  # Update with your real email address
      extraConfig = {
        core.editor = "vim";
      };
    };

    # Install some basic packages
    home.packages = with pkgs; [
      neovim
      htop
      wget
      tree
    ];
  };
}
