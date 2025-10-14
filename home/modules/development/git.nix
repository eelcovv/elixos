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

      # Disable pager for 'git branch' and optionally others
      pager.branch = "false";
      pager.diff = "false";
      pager.log = "false";
    };
  };
}
