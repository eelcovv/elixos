{ lib, config, pkgs, userName, userEmail, ... }:

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
