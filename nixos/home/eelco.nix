{ config, pkgs, lib, ... }:


let
  # Always familiar keys for all hosts
  trustedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC3+DBjLHGlQinS0+qeC5JgFakaPFc+b+btlZABO7ZX6 eelco@tongfang"
  ];

  # Extra keys per specific host
  hostSpecificKeys = {
    tongfang = [ ];
    generic-vm = [ ];
  };

  # The full list: TrustedKeys + Possible host-specific
  keys = trustedKeys ++ (hostSpecificKeys.${config.networking.hostName} or [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC3+DBjLHGlQinS0+qeC5JgFakaPFc+b+btlZABO7ZX6 eelco@tongfang"
 ]);
in
{

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
      htop
      wget
      tree
    ];
  };
}
