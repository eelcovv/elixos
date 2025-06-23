{ config, pkgs, lib, ... }@args:

let
  userName = args.userName or "Set your name";
  userEmail = args.userEmail or "your@email.com";
in {
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
