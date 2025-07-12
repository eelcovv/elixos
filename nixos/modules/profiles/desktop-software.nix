{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    firefox
    google-chrome
    vlc
    libreoffice
    gimp
    filezilla
    krita
  ];
}
