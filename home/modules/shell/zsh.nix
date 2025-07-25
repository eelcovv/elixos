{
  config,
  pkgs,
  lib,
  ...
}: let
  # Choose one: "powerlevel10k", "ohmyposh", "robbyrussell", "agnoster", "af-magic", etc.
  promptStyle = "powerlevel10k";

  # Safeguard: only allow supported options
  validPromptStyles = ["powerlevel10k" "ohmyposh" "robbyrussell" "agnoster" "af-magic"];
in {
  # Ensure only valid prompt styles are accepted
  assertions = [
    {
      assertion = builtins.elem promptStyle validPromptStyles;
      message = "Invalid promptStyle: ${promptStyle}. Must be one of: ${lib.concatStringsSep ", " validPromptStyles}";
    }
  ];

  programs.zsh = {
    enable = true;

    autosuggestion.enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;

    oh-my-zsh = {
      enable = true;

      # Disable oh-my-zsh theme if powerlevel10k or ohmyposh is selected
      theme = lib.mkIf (promptStyle != "powerlevel10k" && promptStyle != "ohmyposh") promptStyle;

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

    initContent = ''
      ${lib.optionalString (promptStyle == "powerlevel10k") ''
        source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
        [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
      ''}

      ${lib.optionalString (promptStyle == "ohmyposh") ''
        eval "$(oh-my-posh init zsh --config $HOME/.config/ohmyposh/zen.toml)"
      ''}

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

  # Prompt-specific files
  xdg.configFile."ohmyposh/zen.toml".source = ./ohmyposh/zen.toml;
  home.file.".p10k.zsh".source = ./p10k.zsh;

  home.packages = with pkgs; [
    zsh
    fzf
    oh-my-posh
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-powerlevel10k
  ];
}
