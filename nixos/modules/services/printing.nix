# nixos/modules/services/printing.nix
{pkgs, ...}: {
  services.printing = {
    enable = true;
    webInterface = true;
    drivers = with pkgs; [gutenprint brlaser];
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
        # Optie 1: vast IP (robuust)
        deviceUri = "ipps://192.168.000.139/ipp/print";
        model = "everywhere";
        ppdOptions = {
          PageSize = "A4";
          Duplex = "DuplexNoTumble";
        };
      }
      # Of optie 2: mDNS-hostnaam zodra je die weet
      # { name = "Brother_DCP_L2530DW";
      #   deviceUri = "ipps://BRWXXXXXXX.local/ipp/print";
      #   model = "everywhere";
      #   ppdOptions = { PageSize = "A4"; Duplex = "DuplexNoTumble"; };
      # }
    ];
  };

  # (optioneel) maak ensure-printers iets toleranter voor Wi-Fi timing
  systemd.services.ensure-printers = {
    after = ["NetworkManager-wait-online.service" "cups.service"];
    wants = ["NetworkManager-wait-online.service" "cups.service"];
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "15s";
      StartLimitIntervalSec = 0;
    };
  };
}
