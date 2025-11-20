{lib, ...}: {
  programs.git = {
    enable = true;
    settings = {
      user.name = lib.mkDefault "Default User";
      user.email = lib.mkDefault "default@example.com";
      core.editor = "vim";
      color.ui = true;
      pull.rebase = false;
    };
  };
}
