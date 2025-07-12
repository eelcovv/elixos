{ lib, config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    initContent = ''
      bindkey -v
      export KEYTIMEOUT=1
      if [ "$TERM" = "xterm-ghostty" ]; then
        export TERM=xterm-256color
      fi
    '';
  };
}
