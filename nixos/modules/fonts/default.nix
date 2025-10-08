{
  config,
  pkgs,
  lib,
  ...
}: {
  fonts = {
    fontconfig.enable = true;

    packages = with pkgs; [
      # basis
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
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
      stix-two # STIX Two Math
      xits-math
      libertinus # Libertinus + Libertinus Math

      # fallbacks die davefonts gebruikt
      roboto
      dejavu_fonts

      # TeX Gyre families (let op koppeltekens)
      tex-gyre-heros
      tex-gyre-pagella
    ];
  };
}
