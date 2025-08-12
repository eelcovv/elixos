{ config, pkgs, lib, ... }:
let
  cfg = config.shells.zsh;
  validPromptStyles = [ "powerlevel10k" "ohmyposh" "robbyrussell" "agnoster" "af-magic" ];
in
{
  options.shells.zsh = {
    enable = lib.mkEnableOption "Enable Zsh configuration" // { default = true; };

    promptStyle = lib.mkOption {
      type = lib.types.enum validPromptStyles;
      default = "powerlevel10k";
      description = "Zsh prompt theme.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = builtins.elem cfg.promptStyle validPromptStyles;
        message = "Invalid promptStyle: ${cfg.promptStyle}. Must be one of: ${lib.concatStringsSep \", \" validPromptStyles}";
      }
    ];

    programs.zsh = {
      enable = true;
      shellAliases.vi = "nvim";

      autosuggestion.enable = true;
      enableCompletion = true;
      syntaxHighlighting.enable = true;

      oh-my-zsh = {
        enable = true;
        # Alleen thema zetten als het géén p10k/ohmyposh is
        theme = lib.mkIf (cfg.promptStyle != "powerlevel10k" && cfg.promptStyle != "ohmyposh") cfg.promptStyle;
        plugins = [
          "git" "z" "sudo" "fzf" "colored-man-pages" "web-search"
          "copyfile" "copybuffer" "dirhistory"
        ];
      };

      initContent = ''
        ${lib.optionalString (cfg.promptStyle == "powerlevel10k") ''
          source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
          [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
        ''}

        ${lib.optionalString (cfg.promptStyle == "ohmyposh") ''
          eval "$(oh-my-posh init zsh --config $HOME/.config/ohmyposh/zen.toml)"
        ''}

        bindkey -v
        export KEYTIMEOUT=1

        if [ "$TERM" = "xterm-ghostty" ]; then
          export TERM=xterm-256color
        fi

        # FZF key bindings (CTRL-R)
        source <(fzf --zsh)

        # History
        HISTFILE=~/.zsh_history
        HISTSIZE=10000
        SAVEHIST=10000
        setopt appendhistory
      '';
    };

    # Prompt-specifieke bestanden
    xdg.configFile."ohmyposh/zen.toml".source = ./ohmyposh/zen.toml;
    home.file.".p10k.zsh".source = ./p10k.zsh;

    home.packages = with pkgs; [
      zsh fzf oh-my-posh zsh-autosuggestions zsh-syntax-highlighting zsh-powerlevel10k
    ];
  };
}
