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
      # Voeg hier de agenda toe
      calendars = [
        {
          name = "DAVE";
          url = "https://nx64056.your-storageshare.de/apps/calendar/p/iMZMzjgCtjWJd3Ja";
          readOnly = false; #
          username = "eelco@davelab.nl";
        }
      ];
    };
  };

  accounts.email.accounts = {
    # Je primaire account
    eelco = {
      primary = true;
      address = "eelco@davelab.nl";
      userName = "eelco@davelab.nl";
      realName = "Eelco van Vliet";
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
      };

      thunderbird.enable = true;
    };

    # Het 'contact' account
    contact = {
      address = "contact@davelab.nl";
      userName = "contact@davelab.nl";
      realName = "Contact Davelab"; # Je kunt hier een andere naam opgeven
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
      };

      thunderbird.enable = true;
    };

    # Het 'ods' account
    ods = {
      address = "ods@davelab.nl";
      userName = "ods@davelab.nl";
      realName = "ODS Davelab"; # Je kunt hier een andere naam opgeven
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
      };

      thunderbird.enable = true;
    };
  };
}
