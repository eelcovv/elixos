{ config, pkgs, lib, userName, userEmail, ... }:

{
  programs.git = {
    enable = true;
    userName = userName;
    userEmail = userEmail;
    extraConfig = {
      core.editor = "vim";
      color.ui = true;
    };
  };
}
