{
  pkgs,
  lib,
  ...
}: let
  tex = pkgs.texlive.combined.scheme-full;
in {
  home.packages = [
    tex
    pkgs.perl # l3Build uses Perl;can be handy
    pkgs.l3build # From Tex Live;Some channels ship it loose
  ];

  # XDG conforming paths, but without overwriting Texmfvar/Texmfconfig
  home.sessionVariables = {
    TEXMFHOME = "$HOME/.local/share/texmf";
    TEXMFCACHE = "$HOME/.cache/texmf-var"; # schrijfbare cache
    # Very important: do not put Texmfvar/Texmfconfig/Texmfcnf yourself
  };

  # Ensure that directories exist with normal permissions
  home.file.".local/share/texmf/.keep".text = "";
  home.file.".cache/texmf-var/.keep".text = "";

  # Easy command with correct ENV
  programs.bash.initExtra = ''
    alias l3bi='env -u TEXMFVAR -u TEXMFCONFIG \
      TEXMFCACHE="$HOME/.cache/texmf-var" \
      TEXMFHOME="$HOME/.local/share/texmf" \
      l3build install --full'
  '';
  programs.zsh.initExtra = ''
    alias l3bi='env -u TEXMFVAR -u TEXMFCONFIG \
      TEXMFCACHE="$HOME/.cache/texmf-var" \
      TEXMFHOME="$HOME/.local/share/texmf" \
      l3build install --full'
  '';
}
