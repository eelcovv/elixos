{ pkgs, ... }:
let
  nextcloud = import ./nextcloud.nix { inherit pkgs; };
in {
  home.packages = with pkgs; [
    telegram-desktop
    wasistlos
    signal-desktop
  ];
}
