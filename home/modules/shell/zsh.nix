{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.zsh = {
    enable = true;
    enableAutosuggestions.enable = true;
    enableSyntaxHighlighting.enable = true;
    oh-my-zsh = {
      enable = true;
      theme = "agnoster";
    };
  };

  home.packages = with pkgs; [
    fzf
    zsh
  ];
}
