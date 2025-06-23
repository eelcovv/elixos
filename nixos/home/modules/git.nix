{ config, pkgs, lib, userName, userEmail, ... }:

{
  programs.git = {
    enable = true;
    user = {
      name = userName;
      email = userEmail;
    };
    extraConfig = {
      core.editor = "vim";
      color.ui = true;
    };
  };
}