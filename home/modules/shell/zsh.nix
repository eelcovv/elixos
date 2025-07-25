{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.zsh = {
    enable = true;

    autosuggestion.enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;

    # Themas available
    # | Theme           | Kenmerk                                                      |
    # | --------------- | ------------------------------------------------------------ |
    # | `agnoster`      | Git-aware, Powerline-style met segmenten, kleurrijk          |
    # | `robbyrussell`  | Simpel, toont alleen Git-branch bij prompt                   |
    # | `bureau`        | Zakelijk: pad, tijd, git-status                              |
    # | `af-magic`      | Compact, toont exitcode, tijd en git                         |
    # | `powerlevel10k` | Extreem configureerbaar, snel, icons, git, context (extern!) |
    # note: for powerlevel10k you need to add the lines below to source the configuration file

    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [
        "git"
        "z"
        "sudo"
        "fzf"
        "colored-man-pages"
        "web-search"
        "copyfile"
        "copybuffer"
        "dirhistory"
      ];
    };

    # bindkey activates editing mode vi
    initContent = ''
      # uncomment for powerlevel10k
      # source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
      # [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

      # Enable oh-my-posh prompt
      eval "$(oh-my-posh init zsh --config $HOME/.config/ohmyposh/zen.toml)"

      bindkey -v
      export KEYTIMEOUT=1
      if [ "$TERM" = "xterm-ghostty" ]; then
        export TERM=xterm-256color
      fi
      # Set up FZF key bindings (CTRL-R for fuzzy history)
      source <(fzf --zsh)

      # Zsh history settings
      HISTFILE=~/.zsh_history
      HISTSIZE=10000
      SAVEHIST=10000
      setopt appendhistory
    '';
  };

  # needed for ohmyposh
  xdg.configFile."ohmyposh/zen.toml".source = ./ohmyposh/zen.toml;

  home = {
    file.".p10k.zsh".source = ./p10k.zsh;

    packages = with pkgs; [
      fzf
      zsh
      oh-my-posh
      zsh-autosuggestions
      zsh-syntax-highlighting
      zsh-powerlevel10k
    ];
  };
}
