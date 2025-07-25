{
  lib,
  config,
  pkgs,
  ...
}: {
  programs.zsh = {
    enable = true;

    # ohMyZsh = {
    #   enable = true;
    #   theme = "agnoster"; # Of bv. "robbyrussell", "powerlevel10k" als je dat later toevoegt
    #   plugins = [
    #     "git"
    #     "z"
    #     "sudo"
    #     "fzf"
    #     "colored-man-pages"
    #   ];
    # };

    #enableCompletion = true;

    # autosuggestions.enable = true;
    #syntaxHighlighting.enable = true;

    #initExtra = ''
    #  bindkey -v
    #  export KEYTIMEOUT=1
    #  if [ "$TERM" = "xterm-ghostty" ]; then
    #    export TERM=xterm-256color
    #  fi
    #'';
  };

  home.packages = with pkgs; [
    fzf
    zsh
  ];
}
