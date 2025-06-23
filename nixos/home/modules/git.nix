{ config, pkgs, lib, ... }:

{
  programs.git = {
    enable = true;

    userName  = "Eelco van Vliet";
    userEmail = "eelcovv@gmail.com";

    extraConfig = {
      core.editor = "vim";
      color.ui = true;
    };
  };
}
