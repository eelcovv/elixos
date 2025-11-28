# nixos/modules/services/printing.nix
{
  lib,
  pkgs,
  ...
}: {
  ##############################################################################
  # System-wide CUPS setup with a fixed IPP queue for Brother DCP-L2530DW
  ##############################################################################
  services.printing = {
    enable = true;
    webInterface = true; # CUPS UI: http://localhost:631
    drivers = with pkgs; [
      gutenprint # generic drivers
      brlaser # Brother open driver (backup)
    ];
    browsed.enable = false; # we use a fixed queue, not autodiscovery
  };

  # mDNS/Avahi optional but harmless
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  ##############################################################################
  # Declarative printer queue
  ##############################################################################
  hardware.printers = {
    ensureDefaultPrinter = "Brother_DCP_L2530DW";
    ensurePrinters = [
      {
        name = "Brother_DCP_L2530DW";
        # ip of wifi at the first floor
        deviceUri = "ipp://192.168.0.139/ipp/print";
        model = "everywhere"; # IPP Everywhere (driverless)
        ppdOptions = {
          PageSize = "A4";
          Duplex = "DuplexNoTumble"; # long-edge duplex on A4
        };
      }
    ];
  };

  ##############################################################################
  # Ensure printers service waits for network and retries
  ##############################################################################
  systemd.services.ensure-printers = {
    after = ["NetworkManager-wait-online.service" "cups.service"];
    wants = ["NetworkManager-wait-online.service" "cups.service"];
    wantedBy = ["multi-user.target"];
    unitConfig = {
      StartLimitIntervalSec = "0";
    };
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "15s";
      SuccessExitStatus = [0];
    };
  };

  ##############################################################################
  # SANE (Scanner Access Now Easy) configuration for Brother DCP-L2530DW
  ##############################################################################
  hardware.sane = {
    enable = true;
    # sane-airscan is a universal driver for modern network scanners (eSCL/WSD)
    extraBackends = [ pkgs.sane-airscan ];
  };

  # sane-airscan uses mDNS (Avahi, already enabled) for discovery.
  # No extra firewall ports are typically needed if Avahi is correctly set up
  # with openFirewall = true.
}
