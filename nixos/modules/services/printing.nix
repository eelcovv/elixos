{pkgs, ...}: {
  ##############################################################################
  # System-wide printing stack (CUPS) + mDNS discovery (Avahi)
  #
  # Why system-level (and not Home-Manager)?
  # - CUPS is a system service (root-owned), GUI tools talk to system cups.
  # - Drivers/PPDs are system packages.
  ##############################################################################
  services.printing = {
    enable = true;

    # Install a few common driver packs. Keep it lean; add/remove as needed.
    drivers = with pkgs; [
      gutenprint # broad coverage for many brands
      brlaser # open-source driver for many Brother mono lasers
      # hplip     # example for HP; not needed for Brother
    ];

    # Handy: enable the CUPS web UI at http://localhost:631
    webInterface = true;
  };

  # Avahi (mDNS) is required for IPP Everywhere / AirPrint auto-discovery.
  services.avahi = {
    enable = true;
    nssmdns4 = true; # resolve *.local hostnames
    openFirewall = true; # allow mDNS on the LAN
  };

  ##############################################################################
  # Declarative printers:
  # - For modern Wi-Fi printers that support IPP Everywhere, prefer "model = \"everywhere\"".
  # - If your network advertises the printer via mDNS, use its .local name.
  # - You can discover URIs with: `lpinfo -v` or `avahi-browse -rt _ipp._tcp`.
  ##############################################################################
  hardware.printers = {
    # Optional: pick a default printer by name
    ensureDefaultPrinter = "Brother_DCP_L2530DW";

    ensurePrinters = [
      # --- Option A (recommended): IPP Everywhere over Wi-Fi -----------------
      {
        name = "Brother_DCP_L2530DW";
        #
        # Common device URIs (pick the one that works on your network):
        # - "ipp://brother.local/ipp/print"
        # - "ipp://Brother.local/ipp/print"
        # - "ipp://BRWXXXXXXXXXXXX.local/ipp/print"   (Brother’s mDNS name)
        # - "ipp://<printer-ip>/ipp/print"            (static IP)
        #
        deviceUri = "ipp://brother.local/ipp/print";

        # IPP Everywhere = driverless; CUPS negotiates capabilities automatically.
        model = "everywhere";

        # Useful defaults; adjust as needed.
        ppdOptions = {
          PageSize = "A4";
          Duplex = "DuplexNoTumble"; # long-edge duplex on A4
        };
      }

      # --- Option B (fallback): explicit Brother driver via brlaser ----------
      # Uncomment this block if you prefer/need a PPD-based setup.
      # To get the exact model string, run: `lpinfo -m | grep -i brother`
      # {
      #   name = "Brother_DCP_L2530DW_brlaser";
      #   deviceUri = "ipp://brother.local/ipp/print"; # or lpd://<ip>/queue
      #
      #   # Example model string (NOTE: use one returned by `lpinfo -m`):
      #   # model = "drv:///brlaser.drv/br3250.ppd";   # <-- placeholder example
      #   # If unsure, try a nearby family model; brlaser covers many L23xx/L25xx.
      #
      #   ppdOptions = { PageSize = "A4"; Duplex = "DuplexNoTumble"; };
      # }
    ];
  };
}
