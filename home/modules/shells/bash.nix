{pkgs, ...}: {
  home.packages = with pkgs; [
    bashInteractive
    bash-completion
    fzf
    oh-my-posh
    direnv
  ];

  home.file.".bashrc".text = ''
    # ----- Editor & PATH -----
    export EDITOR=vim
    export PATH="$HOME/bin:$PATH"

    # ----- Aliases -----
    alias ll='ls -lah'
    alias gs='git status'
    alias vi='nvim'

    # ----- History settings (append + grotere geschiedenis) -----
    shopt -s histappend
    HISTFILE="$HOME/.bash_history"
    HISTSIZE=10000
    HISTFILESIZE=20000
    # Dubbele/spaties-commands niet in history
    HISTCONTROL=ignoredups:ignorespace

    # ----- vi-mode (zoals bindkey -v in zsh) -----
    set -o vi
    # Snellere ESC (optioneel): verklein de timeout van keyseqs
    # bind 'set keyseq-timeout 25'

    # ----- Ghostty TERM fix -----
    if [ "$TERM" = "xterm-ghostty" ]; then
      export TERM=xterm-256color
    fi

    # ----- Bash completion -----
    if [ -f /etc/bash_completion ]; then
      . /etc/bash_completion
    elif [ -f "${pkgs.bash-completion}/etc/profile.d/bash_completion.sh" ]; then
      . "${pkgs.bash-completion}/etc/profile.d/bash_completion.sh"
    fi

    # ----- fzf keybindings & completion (alleen als fzf aanwezig is) -----
    if command -v fzf >/dev/null 2>&1; then
      # Nix' fzf levert shell-integraties via deze subshell-call
      source <(fzf --bash) 2>/dev/null || true
    fi

    # ----- Direnv hook (alleen als aanwezig) -----
    if command -v direnv >/dev/null 2>&1; then
      eval "$(direnv hook bash)"
    fi

    # ----- Oh-My-Posh prompt (zelfde theme als zsh) -----
    if command -v oh-my-posh >/dev/null 2>&1; then
      eval "$(oh-my-posh init bash --config "$HOME/.config/ohmyposh/zen.toml")"
    else
      # Fallback PS1 als oh-my-posh ontbreekt
      PS1='\u@\h:\w\$ '
    fi

    # ----- Kleurrijke man-pages (equivalent van colored-man-pages) -----
    export LESS=-R
    export LESS_TERMCAP_mb=$'\e[1;31m'
    export LESS_TERMCAP_md=$'\e[1;36m'
    export LESS_TERMCAP_me=$'\e[0m'
    export LESS_TERMCAP_so=$'\e[01;44;37m'
    export LESS_TERMCAP_se=$'\e[0m'
    export LESS_TERMCAP_us=$'\e[1;32m'
    export LESS_TERMCAP_ue=$'\e[0m'

    # ----- Directory history helpers (globaal vergelijkbaar met dirhistory) -----
    alias d='dirs -v'
    for index in {1..9}; do
      eval "alias $index='cd +$index 2>/dev/null || true'"
    done
  '';
}
