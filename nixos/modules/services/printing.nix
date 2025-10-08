{pkgs, ...}: {
  services.printing = {
    enable = true;
    drivers = [pkgs.hplip];
  };

  services.avahi = {
    enable = true;
    nssmdns = true;
  };

  hardware.printers = {
    enable = true;
    autoDiscover = true;
  };
}
