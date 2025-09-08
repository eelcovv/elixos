{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.thunderbird = {
    enable = true;
    profiles.default = {
      isDefault = true;
      settings = {
        "extensions.autoDisableScopes" = 0;

        # Iets langere netwerk-timeout (default is vrij krap)
        "mailnews.tcptimeout" = 200;

        # Alleen inschakelen als je echt IPv6-problemen ziet:
        # "network.dns.disableIPv6" = true;
      };
      extensions = [];
    };
  };

  accounts.email.accounts = {
    eelco = {
      primary = true;
      address = "eelco@davelab.nl";
      userName = "eelco@davelab.nl";
      realName = "Eelco van Vliet";
      flavor = "plain";

      imap = {
        host = "mail.davelab.nl";
        port = 993;
        tls.enable = true; # IMAPS
      };

      smtp = {
        host = "mail.davelab.nl";
        port = 587;
        tls.enable = true; # TLS gebruiken
        tls.useStartTls = true; # STARTTLS is vereist op 587
      };

      thunderbird.enable = true;
      thunderbird.profiles = ["default"];
    };

    contact = {
      address = "contact@davelab.nl";
      userName = "contact@davelab.nl";
      realName = "Contact Davelab";
      flavor = "plain";

      imap = {
        host = "mail.davelab.nl";
        port = 993;
        tls.enable = true;
      };
      smtp = {
        host = "mail.davelab.nl";
        port = 587;
        tls.enable = true;
        tls.useStartTls = true;
      };
      thunderbird.enable = true;
      thunderbird.profiles = ["default"];
    };

    ods = {
      address = "ods@davelab.nl";
      userName = "ods@davelab.nl";
      realName = "ODS Davelab";
      flavor = "plain";

      imap = {
        host = "mail.davelab.nl";
        port = 993;
        tls.enable = true;
      };
      smtp = {
        host = "mail.davelab.nl";
        port = 587;
        tls.enable = true;
        tls.useStartTls = true;
      };
      thunderbird.enable = true;
      thunderbird.profiles = ["default"];
    };
  };
}
