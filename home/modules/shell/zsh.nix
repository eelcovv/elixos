{ config, pkgs, lib, ... }: {
  programs.zsh = {
    enable = true;

    autosuggestion.enable = true;
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
      theme = "powerlevel10k";
    };
  };

  home.packages = with pkgs; [
    fzf
    zsh
];
}

