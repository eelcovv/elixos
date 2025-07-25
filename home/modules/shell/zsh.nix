{
  programs.zsh = {
    enable = true;

    ohMyZsh = {
      enable = true;
      theme = "agnoster";
      plugins = [
        "git"
        "z"
        "fzf"
        "colored-man-pages"
        "zsh-autosuggestions"
        "zsh-syntax-highlighting"
      ];
    };
  };

  home.packages = with pkgs; [
    fzf
    zsh
    oh-my-zsh
    zsh-autosuggestions
    zsh-syntax-highlighting
  ];
}
