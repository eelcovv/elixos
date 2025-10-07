{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.shells.zsh;
  validPromptStyles = ["powerlevel10k" "ohmyposh" "robbyrussell" "agnoster" "af-magic"];
in {
  options.shells.zsh = {
    enable = lib.mkEnableOption "Enable Zsh configuration" // {default = true;};

    promptStyle = lib.mkOption {
      type = lib.types.enum validPromptStyles;
      default = "powerlevel10k";
      description = "Zsh prompt theme.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.zsh = {
      enable = true;
      shellAliases.vi = "nvim";
      autosuggestion.enable = true;
      enableCompletion = true;
      syntaxHighlighting.enable = true;

      oh-my-zsh = {
        enable = true;
        theme = lib.mkIf (cfg.promptStyle != "powerlevel10k" && cfg.promptStyle != "ohmyposh") cfg.promptStyle;
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
        # Keep the chosen prompt style available in the shell session for later restoration
        export ZSH_PROMPT_STYLE="${lib.escapeShellArg cfg.promptStyle}"

        ${lib.optionalString (cfg.promptStyle == "powerlevel10k") ''
          source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
          [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
        ''}

        ${lib.optionalString (cfg.promptStyle == "ohmyposh") ''
          eval "$(oh-my-posh init zsh --config "$HOME/.config/ohmyposh/zen.toml")"
        ''}

        bindkey -v
        export KEYTIMEOUT=1
        if [ "$TERM" = "xterm-ghostty" ]; then export TERM=xterm-256color; fi
        command -v fzf >/dev/null 2>&1 && source <(fzf --zsh)
        HISTFILE=~/.zsh_history; HISTSIZE=10000; SAVEHIST=10000; setopt appendhistory

        # ---------- Universal OSC helpers (fallback when not using Kitty) ----------
        _osc4_set() { printf '\033]4;%d;#%s\007' "$1" "$2"; }  # set ANSI color slot n to #RRGGBB

        panic-osc-theme() {
          # High-contrast white-on-black + 16-slot palette
          printf '\033]10;#ffffff\007'   # foreground
          printf '\033]11;#000000\007'   # background
          printf '\033]12;#ffffff\007'   # cursor
          _osc4_set 0 000000; _osc4_set 1 ff5555; _osc4_set 2 50fa7b; _osc4_set 3 f1fa8c
          _osc4_set 4 bd93f9; _osc4_set 5 ff79c6; _osc4_set 6 8be9fd; _osc4_set 7 bbbbbb
          _osc4_set 8 444444; _osc4_set 9 ff6e6e; _osc4_set 10 69ff94; _osc4_set 11 ffffa5
          _osc4_set 12 caa9ff; _osc4_set 13 ff92df; _osc4_set 14 a4ffff; _osc4_set 15 ffffff
        }

        reset-osc-theme() {
          # Restore conservative defaults — adjust these to your normal theme colors
          printf '\033]10;#d0d0d0\007'   # foreground
          printf '\033]11;#101010\007'   # background
          printf '\033]12;#d0d0d0\007'   # cursor
        }
        panic-toggle() {
          if [ -n "$_PANIC_ACTIVE" ]; then
            reset-theme
            unset _PANIC_ACTIVE
            print "🔄 Panic mode deactivated."
          else
            panic-theme
            export _PANIC_ACTIVE=1
            print "🔄 Panic mode activated."
          fi
        }

        # ---------- ZSH syntax-highlighting: safe styles for "panic" ----------
        _apply_safe_highlighting() {
          # Recreate as a global associative array and fill with conservative styles
          typeset -gA ZSH_HIGHLIGHT_STYLES

          # Only widely-supported keys and basic colors
          ZSH_HIGHLIGHT_STYLES[default]='fg=white'
          ZSH_HIGHLIGHT_STYLES[command]='fg=white,bold'
          ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=white,bold'
          ZSH_HIGHLIGHT_STYLES[builtin]='fg=white,bold'
          ZSH_HIGHLIGHT_STYLES[alias]='fg=white,bold'

          # Paths shown during e.g. `cd`
          ZSH_HIGHLIGHT_STYLES[path]='fg=white,underline'

          # Arguments / globs
          ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=yellow'
          ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=yellow'
          ZSH_HIGHLIGHT_STYLES[globbing]='fg=cyan,bold'

          # Comments
          ZSH_HIGHLIGHT_STYLES[comment]='fg=blue'
        }

        # Instead of `unset`, reinitialize to an empty associative array
        _clear_safe_highlighting() {
          typeset -gA ZSH_HIGHLIGHT_STYLES
          ZSH_HIGHLIGHT_STYLES=()
        }

        # ---------- Prompt switchers ----------
        _set_simple_prompt() {
          if command -v oh-my-posh >/dev/null 2>&1; then
            # "paradox" is simple and high-contrast
            eval "$(oh-my-posh init zsh --config 'paradox')"
          else
            # Fallback to a minimal p10k if present
            if [ -f ~/.p10k.zsh ]; then
              source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
              source ~/.p10k.zsh
            fi
          fi
        }

        _restore_prompt() {
          case "$ZSH_PROMPT_STYLE" in
            ohmyposh)
              command -v oh-my-posh >/dev/null 2>&1 && eval "$(oh-my-posh init zsh --config "$HOME/.config/ohmyposh/zen.toml")"
              ;;
            powerlevel10k)
              source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
              [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
              ;;
            *)
              # oh-my-zsh classic themes are already handled via programs.zsh.oh-my-zsh.theme
              ;;
          esac
        }

        # ---------- Panic/Reset for all terminals ----------
        panic-theme() {
          local applied=""

          # 1) Prefer Kitty remote control (instant, palette level)
          if command -v kitty >/dev/null 2>&1 && { [ -n "$KITTY_LISTEN_ON" ] || [ "$TERM" = "xterm-kitty" ]; }; then
            kitty @ set-colors --all --configured "$HOME/.config/kitty/settings/panic.conf" >/dev/null 2>&1 && applied="kitty"
            # Force full opacity during panic
            kitty @ set-background-opacity 1 >/dev/null 2>&1 || true
          fi

          # 2) Fallback: OSC (works in many terminals, including Ghostty)
          if [ -z "$applied" ]; then
            panic-osc-theme
            applied="osc"
          fi

          # 3) Make prompt and highlighting safer
          # _set_simple_prompt
          _apply_safe_highlighting

          # 4) Optional: high-contrast LS_COLORS for ls/eza (comment out if undesired)
          export _PANIC_OLD_LS_COLORS="$LS_COLORS"
          export LS_COLORS='di=01;34:ln=01;36:so=01;35:pi=33:ex=01;32:bd=01;33:cd=01;33:su=01;31:sg=01;31:tw=01;34:ow=01;34:'

          print "✅ Panic theme applied ($applied: high-contrast palette + safer prompt/highlighting)."
        }

        reset-theme() {
          local reset_by=""

          # 1) Prefer Kitty reset back to your wallust/matugen theme
          if command -v kitty >/dev/null 2>&1 && { [ -n "$KITTY_LISTEN_ON" ] || [ "$TERM" = "xterm-kitty" ]; }; then
            # Try matugen first, fall back to wallust
            if [ -f "$HOME/.config/kitty/colors-matugen.conf" ]; then
              kitty @ set-colors --all --configured "$HOME/.config/kitty/colors-matugen.conf" >/dev/null 2>&1 && reset_by="kitty"
            else
              kitty @ set-colors --all --configured "$HOME/.config/kitty/colors-wallust.conf" >/dev/null 2>&1 && reset_by="kitty"
            fi
            # Restore your normal semi-transparency
            kitty @ set-background-opacity 0.7 >/dev/null 2>&1 || true
          fi

          # 2) Fallback: restore via OSC
          if [ -z "$reset_by" ]; then
            reset-osc-theme
            reset_by="osc"
          fi

          # 3) Restore your normal prompt and clear highlighting overrides
          _restore_prompt
          _clear_safe_highlighting

          # 4) Restore previous LS_COLORS if we changed it
          if [ -n "$_PANIC_OLD_LS_COLORS" ]; then
            export LS_COLORS="$_PANIC_OLD_LS_COLORS"
            unset _PANIC_OLD_LS_COLORS
          fi

          print "↩️  Theme reset ($reset_by)."
        }
      '';
    };

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
  };
}
