{
  config,
  lib,
  pkgs,
  ...
}: let
  # Full set: everything works without hassle
  tex = pkgs.texlive.combined.scheme-full;
  # -alternative (slimmer set): uncomwet if you want smaller-
  # tex = pkgs.texlive.combine {
  #   inherit (pkgs.texlive)
  #     scheme-medium
  #     xetex
  #     luatex
  #     latexmk
  #     l3build
  #     texlive-scripts
  #     collection-xetex
  #     collection-luatex
  #     collection-latexrecommended
  #     collection-fontsrecommended;
  # };
in {
  home.packages = [
    tex
  ];

  # Provide consistent Texmf paths (no Global /Nix /Store Writables required)
  home.sessionVariables = {
    TEXMFHOME = "${config.home.homeDirectory}/.texmf";
    TEXMFVAR = "${config.xdg.cacheHome}/texmf-var";
  };

  #Create directories before you start building
  home.activation.texmfDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "${config.home.homeDirectory}/.texmf" "${config.xdg.cacheHome}/texmf-var"
  '';
}
