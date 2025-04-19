{ pkgs, ... }:

{
  imports = [
    # hier kun je later eventueel meer globale modules toevoegen
  ];

  services.openssh.enable = true;
  services.pipewire.enable = true;
  networking.networkmanager.enable = true;
  i18n.defaultLocale = "en_US.UTF-8";

  time.timeZone = "Europe/Amsterdam";

  environment.systemPackages = with pkgs; [
    vim
    git
    curl
  ];
}
