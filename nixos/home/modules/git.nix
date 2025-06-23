{ config, pkgs, lib, ... }:

{
  programs.git = {
    enable = true;
    userName = lib.mkDefault "Set your name";
    userEmail = lib.mkDefault "your@email.com";
    extraConfig = {
      core.editor = "vim";
      color.ui = true;
    };
  };
}

