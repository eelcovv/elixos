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

    # Use home.file to directly write the authorized_keys file
    home.file.".ssh/authorized_keys".text = ''
      ${builtins.toString keys}
    '';

    # Ensure .ssh directory has correct permissions
    home.file.".ssh".mode = "700";
    home.file.".ssh".owner = "eelco";
    home.file.".ssh".group = "eelco";

    # Ensure authorized_keys file has correct permissions
    home.file.".ssh/authorized_keys".mode = "600";
    home.file.".ssh/authorized_keys".owner = "eelco";
    home.file.".ssh/authorized_keys".group = "eelco";

    # Enable SSH program to allow ssh client usage
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
