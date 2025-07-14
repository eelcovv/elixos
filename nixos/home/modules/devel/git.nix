{
  config,
  pkgs,
  lib,
  userName ? "Default User",
  userEmail ? "default@example.com",
  ...
}: {
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
