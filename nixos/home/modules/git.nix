# modules/git.nix
{ config, pkgs, lib, userName, userEmail, ... }:

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

