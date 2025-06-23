{ config, pkgs, lib, ... }:

{
  programs.git = {
    enable = true;
    user = {
      name = "Eelco van Vliet";
      email = "eelcovv@gmail.com";
    };
    extraConfig = {
      core.editor = "vim";
      color.ui = true;
    };
  };
}
