{ config, pkgs, lib, ... }:

{
  home-manager.users.eelco = {
    home.username = "eelco";
    home.homeDirectory = "/home/eelco";
    home.stateVersion = "24.11";

    home.file.".ssh/id_ed25519" = {
      source = config.age.secrets.ssh_key_generic_vm_eelco.path;
      mode = "0600";
    };

    # Shell (zsh) config
    programs.zsh = {
      enable = true;
    };

    # Git config
    programs.git = {
      enable = true;
      userName = "Eelco van Vliet";
      userEmail = "eelcovv@gmail.com"; # Update with your real email address
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
