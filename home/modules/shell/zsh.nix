{
  lib,
  config,
  pkgs,
  ...
}: {
  programs.zsh = {
    enable = true;

    ohMyZsh = {
      enable = true; # ✅ dit is verplicht!
      theme = "agnoster";
    };

    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
  };

  home.packages = with pkgs; [
    fzf
    zsh
    oh-my-zsh
  ];
}
