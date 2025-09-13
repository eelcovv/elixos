{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.alacritty = {
    enable = true;

    settings = {}; # optioneel leeg, want we gebruiken alacritty.toml

    # Je kunt eventueel inline settings hier toevoegen i.p.v. met .toml
    # settings = {
    #   font.size = 12.0;
    #   window.opacity = 0.85;
    # };
  };

  xdg.configFile."alacritty/alacritty.toml".source = ./alacritty.toml;
}
