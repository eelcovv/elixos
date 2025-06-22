{ config, pkgs, lib, userName, userEmail, ... }:

{
  programs.git = {
    enable = true;
    inherit userName userEmail;
    extraConfig = {
      core.editor = "vim";
      color.ui = true;
    };
  };
}
