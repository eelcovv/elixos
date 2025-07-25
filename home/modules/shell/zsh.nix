{ config, pkgs, lib, ... }: {
  programs.zsh = {
    enable = true;

    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

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

