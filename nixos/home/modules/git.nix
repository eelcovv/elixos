{ config, pkgs, lib, name, email, ... }:

{
  programs.git = {
    enable = true;

    userName  = name;
    userEmail = email;

    extraConfig = {
      core.editor = "vim";
      color.ui    = true;
    };
  };
}
