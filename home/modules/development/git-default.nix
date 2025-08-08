{lib, ...}: {
  programs.git = {
    enable = true;
    userName = lib.mkDefault "Default User";
    userEmail = lib.mkDefault "default@example.com";
    extraConfig = {
      core.editor = "vim";
      color.ui = true;
    };
  };
}
