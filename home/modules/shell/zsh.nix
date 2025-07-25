{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.zsh = {
    enable = true;
    enableAutosuggestions.enable;
    enableSyntaxHighlighting.enable;
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
