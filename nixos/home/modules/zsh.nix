{ lib, config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    initContent = ''
      if [ "$TERM" = "xterm-ghostty" ]; then
        export TERM=xterm-256color
      fi

      # Extra prompt / plugins / theming hier later
    '';
  };
}
