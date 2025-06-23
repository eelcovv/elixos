# modules/git.nix
{ config, pkgs, lib, userName ? "Set your name", userEmail ? "your@email.com", ... }:

{
  programs.git = {
    enable = true;
    userName = lib.mkDefault userName;
    userEmail = lib.mkDefault userEmail;
    extraConfig = {
      core.editor = "vim";
      color.ui = true;
    };
  };
}

