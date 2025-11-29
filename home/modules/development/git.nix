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
    settings = {
      user.name = userName;
      user.email = userEmail;
      core.editor = "vim";
      color.ui = true;

      # Disable pager for 'git branch' and optionally others
      pager.branch = "false";
      pager.diff = "false";
      pager.log = "false";
    };
  };
}
