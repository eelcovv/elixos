{pkgs, ...}: {
  config = {
    fonts.packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      font-awesome
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
      nerd-fonts.hack
      nerd-fonts.iosevka
      nerd-fonts.sauce-code-pro
      nerd-fonts.fantasque-sans-mono
      nerd-fonts.mononoki
      stix-two # contains STIX Two Math
      xits-math # XITS Math
      libertinus # Libertinus (incl. Math)

      # optional but handy
      roboto # body/sans fallback
      tex-gyre # TeX Gyre Heros/Pagella etc.
      dejavu_fonts # DejaVu Sans Mono fallback
    ];
  };
}
