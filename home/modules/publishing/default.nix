{pkgs, ...}: let
  tex = pkgs.texlive.combined.scheme-full;
in {
  # 1) Install TeX Live + Perl
  home.packages = [
    tex
    pkgs.perl
  ];

  # 2) Use a classic user tree under ~/texmf
  home.sessionVariables = {
    TEXMFHOME = "$HOME/texmf";
    TEXMFCACHE = "$HOME/.cache/texmf-var";
  };

  # 3) Ensure the trees exist
  home.file."texmf/.keep".text = "";
  home.file.".cache/texmf-var/.keep".text = "";

  # 4) Put ~/.local/bin first so our wrappers are picked up
  home.sessionPath = ["$HOME/.local/bin" "$HOME/.nix-profile/bin"];

  # 5) l3build wrapper: call the TeX Live l3build from the Nix store,
  #    keep default kpathsea search (via '::'), and avoid per-user formats.
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

      # Hint TEXFORMATS to the prebuilt xelatex.fmt if available (optional)
      if fmt="$(kpsewhich -engine=xetex -progname=xelatex -format=fmt xelatex.fmt 2>/dev/null || true)"; then
        if [ -n "''${fmt:-}" ]; then
          export TEXFORMATS="$(dirname "''${fmt}")"
        fi
      fi

      # Ensure default kpathsea trees are included ('::' appends engine defaults)
      if [ -n "''${TEXINPUTS:-}" ]; then
        case "''${TEXINPUTS}" in
          *::* ) : ;;
          *:   ) export TEXINPUTS="''${TEXINPUTS}:" ;;
          *    ) export TEXINPUTS="''${TEXINPUTS}::" ;;
        esac
      else
        export TEXINPUTS="::"
      fi

      # Avoid per-user formats/config so mktexfmt doesn't write under $HOME
      exec env -u TEXMFVAR -u TEXMFCONFIG "$REAL_L3BUILD" "$@"
    '';
  };

  # 6) (Optional) l3typeset wrapper for future doc builds with xelatex.
  #    Not needed for `l3build install`, but handy if you later run `l3build doc`.
  home.file.".local/bin/l3typeset" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      # Detect the TeX Live ".../tex" tree from the Nix store
      dist_tex="$(kpsewhich article.cls 2>/dev/null || true)"
      if [ -n "''${dist_tex}" ]; then
        dist_tex="$(echo "''${dist_tex}" | sed -E 's#/tex/latex/.*#/tex#')"
      fi

      # l3build runs typeset from build/doc; include build/local too
      build_doc="$(pwd)"
      build_local="''${build_doc}/../local"

      # Compose TEXINPUTS: build/doc : build/local : Nix tex tree : defaults
      TEXINPUTS_COMPOSED="''${build_doc}:''${build_local}"
      if [ -n "''${dist_tex}" ]; then
        TEXINPUTS_COMPOSED="''${TEXINPUTS_COMPOSED}:''${dist_tex}//"
      fi
      TEXINPUTS_COMPOSED="''${TEXINPUTS_COMPOSED}::"

      # Unset engine-specific overrides that might mask generic TEXINPUTS
      exec env \
        -u TEXMFVAR -u TEXMFCONFIG \
        -u TEXINPUTS.xelatex -u TEXINPUTS.lualatex -u TEXINPUTS.pdflatex \
        KPSE_DOT="." \
        TEXINPUTS="''${TEXINPUTS_COMPOSED}" \
        xelatex "$@"
    '';
  };
}
