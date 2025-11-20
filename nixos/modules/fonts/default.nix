# nixos/modules/fonts/default.nix
{pkgs, ...}: {
  config = {
    fonts.packages = with pkgs; [
      # basis
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      font-awesome

      # developer/nerd
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
      nerd-fonts.hack
      nerd-fonts.iosevka
      nerd-fonts.sauce-code-pro
      nerd-fonts.fantasque-sans-mono
      nerd-fonts.mononoki

      # math (voor unicode-math)
      stix-two # bevat STIX Two Math
      xits-math
      libertinus # bevat Libertinus (incl. Math)

      # fallbacks die davefonts gebruikt
      roboto
      dejavu_fonts

      # TeX Gyre families — let op: specifieke derivaties, géén attrset
      tex-gyre.heros
      tex-gyre.pagella
    ];
  };
}
