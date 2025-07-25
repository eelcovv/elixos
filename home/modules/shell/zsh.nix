{
  pkgs,
  lib,
  config,
  ...
}: {
  programs.zsh = {
    enable = true;

    oh-my-zsh = {
      enable = true;
      theme = "agnoster"; # Andere opties: "robbyrussell", "powerlevel10k", ...
      plugins = [
        "git"
        "fzf"
        "colored-man-pages"
        "sudo"
      ];
    };

    enableCompletion = true;

    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    initExtra = ''
      bindkey -v
      export KEYTIMEOUT=1

      # Fix voor bepaalde terminals zoals xterm-ghostty
      if [ "$TERM" = "xterm-ghostty" ]; then
        export TERM=xterm-256color
      fi
    '';
  };

  home.packages = with pkgs; [
    fzf
    zsh
  ];
}
