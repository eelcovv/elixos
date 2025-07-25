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

    oh-my-zsh = {
      enable = true;
      theme = "bureau";
      plugins = [
        "git"
        "z"
        "sudo"
        "fzf"
        "colored-man-pages"
      ];
    };

    initExtra = ''
      bindkey -v
      export KEYTIMEOUT=1
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
