# nixos/modules/services/printing.nix
{pkgs, ...}: {
  services.printing = {
    enable = true;
    drivers = with pkgs; [gutenprint brlaser];
    webInterface = true;
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  hardware.printers = {
    ensureDefaultPrinter = "Brother_DCP_L2530DW";

    ensurePrinters = [
      {
        name = "Brother_DCP_L2530DW";
        # Use IPPS (TLS) and a static IP to avoid timing & mDNS issues
        deviceUri = "ipps://192.168.1.123/ipp/print"; # <-- put your printer IP here
        model = "everywhere"; # IPP Everywhere (driverless)
        ppdOptions = {
          PageSize = "A4";
          Duplex = "DuplexNoTumble";
        };
      }
    ];
  };
}
