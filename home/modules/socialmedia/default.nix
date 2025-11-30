{ pkgs, ... }: {
  imports = [
    ./nextcloud-talk.nix
  ];
  home.packages = with pkgs; [
    telegram-desktop
    wasistlos
    signal-desktop
  ];
}
