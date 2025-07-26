{pkgs, ...}: {
  home.file.".bashrc".text = ''
    export EDITOR=vim
    export PATH=$HOME/bin:$PATH
    alias ll="ls -lah"
    alias gs="git status"
  '';
}
