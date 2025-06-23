{ config, pkgs, lib, name, email, ... }:

{
  programs.git = {
    enable = true;
    user = {
      name = name;
      email = email;
    };
    extraConfig = {
      core.editor = "vim";
      color.ui = true;
    };
  };
}
