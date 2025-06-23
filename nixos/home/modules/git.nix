{ config, pkgs, lib, userName, userEmail, ... }:

{
  programs.git = {
    enable = true;
    extraConfig = {
      user.name = userName;
      user.email = userEmail;
      core.editor = "vim";
      color.ui = true;
    };
  };
}
