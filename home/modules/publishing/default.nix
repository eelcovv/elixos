{pkgs, ...}: let
  tex = pkgs.texlive.combined.scheme-full;
in {
  # 1) Install TeX Live + Perl
  home.packages = [
    tex
    pkgs.perl
  ];

  # 2) XDG-vriendelijke persoonlijke trees
  home.sessionVariables = {
    TEXMFHOME = "$HOME/.local/share/texmf";
    TEXMFCACHE = "$HOME/.cache/texmf-var";
  };

  # 3) Zorg dat directories bestaan
  home.file.".local/share/texmf/.keep".text = "";
  home.file.".cache/texmf-var/.keep".text = "";

  # 4) ~/.local/bin vooraan in PATH (zodat onze wrappers winnen)
  home.sessionPath = ["$HOME/.local/bin" "$HOME/.nix-profile/bin"];

  # 5) l3build wrapper
  home.file.".local/bin/l3build" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      REAL_L3BUILD="${tex}/bin/l3build"
      if [ ! -x "$REAL_L3BUILD" ]; then
        echo "l3build wrapper: not found at ${tex}/bin/l3build" >&2
        exit 127
      fi

      # (optioneel) hint naar xelatex.fmt locatie als die vindbaar is
      if fmt="$(kpsewhich -engine=xetex -progname=xelatex -format=fmt xelatex.fmt 2>/dev/null || true)"; then
        if [ -n "''${fmt:-}" ]; then
          export TEXFORMATS="$(dirname "''${fmt}")"
        fi
      fi

      # Zorg dat standaard kpathsea trees altijd meezoeken ( '::' voegt defaults toe )
      if [ -n "''${TEXINPUTS:-}" ]; then
        case "''${TEXINPUTS}" in
          *::* ) : ;;
          *:   ) export TEXINPUTS="''${TEXINPUTS}:" ;;
          *    ) export TEXINPUTS="''${TEXINPUTS}::" ;;
        esac
      else
        export TEXINPUTS="::"
      fi

      # Gebruik geen per-user formats/caches
      exec env -u TEXMFVAR -u TEXMFCONFIG "$REAL_L3BUILD" "$@"
    '';
  };

  # 6) l3typeset wrapper (zet TEXINPUTS.xelatex via `env`, geen bash var met punt)
  home.file.".local/bin/l3typeset" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      # Vind de TeX Live .../tex tree in de Nix store
      dist_tex="$(kpsewhich article.cls 2>/dev/null || true)"
      if [ -n "''${dist_tex}" ]; then
        dist_tex="$(echo "''${dist_tex}" | sed -E 's#/tex/latex/.*#/tex#')"
      fi

      # l3build runt vanuit build/doc; neem ook build/local mee
      build_doc="$(pwd)"
      build_local="''${build_doc}/../local"

      # Stel TEXINPUTS samen: build/doc : build/local : Nix tex tree : defaults
      TEXINPUTS_COMPOSED="''${build_doc}:''${build_local}"
      if [ -n "''${dist_tex}" ]; then
        TEXINPUTS_COMPOSED="''${TEXINPUTS_COMPOSED}:''${dist_tex}//"
      fi
      TEXINPUTS_COMPOSED="''${TEXINPUTS_COMPOSED}::"

      # Belangrijk:
      #  - unset engine-specifieke TEXINPUTS die l3build kan zetten
      #  - zet KPSE_DOT=., zodat relatieve paden goed werken
      exec env \
        -u TEXMFVAR -u TEXMFCONFIG \
        -u TEXINPUTS.xelatex -u TEXINPUTS.lualatex -u TEXINPUTS.pdflatex \
        KPSE_DOT="." \
        TEXINPUTS="''${TEXINPUTS_COMPOSED}" \
        xelatex "$@"
    '';
  };
}
