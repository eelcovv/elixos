{pkgs, ...}: let
  tex = pkgs.texlive.combined.scheme-full;
in {
  # 1) Install TeX Live and Perl only (no separate l3build package)
  home.packages = [
    tex
    pkgs.perl
  ];

  # 2) XDG-friendly personal trees; DO NOT set TEXMFVAR/TEXMFCONFIG here
  home.sessionVariables = {
    TEXMFHOME = "$HOME/.local/share/texmf";
    TEXMFCACHE = "$HOME/.cache/texmf-var";
  };

  # 3) Ensure dirs exist
  home.file.".local/share/texmf/.keep".text = "";
  home.file.".cache/texmf-var/.keep".text = "";

  # 4) Put ~/.local/bin at the front of PATH so our wrapper wins first
  home.sessionPath = ["$HOME/.local/bin" "$HOME/.nix-profile/bin"];

  # 5) Provide a wrapper script at ~/.local/bin/l3build (no package collision)
  home.file.".local/bin/l3build" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      # Resolve the store-provided l3build from TeX Live directly
      REAL_L3BUILD="${tex}/bin/l3build"
      if [ ! -x "$REAL_L3BUILD" ]; then
        echo "l3build wrapper: TeX Live l3build not found at ${tex}/bin/l3build" >&2
        exit 127
      fi

      # Optional: set TEXFORMATS to the store directory of xelatex.fmt if available
      if fmt="$(kpsewhich -engine=xetex -progname=xelatex -format=fmt xelatex.fmt 2>/dev/null || true)"; then
        if [ -n "${fmt:-}" ]; then
          export TEXFORMATS="$(dirname "$fmt")"
        fi
      fi

      # Ensure kpathsea searches default trees in addition to any l3build-local tree.
      # The '::' token inserts the engine's default search path.
      if [ -n "${TEXINPUTS:-}" ]; then
        case "$TEXINPUTS" in
          *::* ) : ;;                          # defaults already included
          *:   ) export TEXINPUTS="${TEXINPUTS}:" ;;  # ensure trailing separator
          *    ) export TEXINPUTS="${TEXINPUTS}::" ;;
        esac
      else
        export TEXINPUTS="::"
      fi

      # Critical: avoid per-user formats/config so mktexfmt is never triggered
      exec env -u TEXMFVAR -u TEXMFCONFIG "$REAL_L3BUILD" "$@"
    '';
  };
}
