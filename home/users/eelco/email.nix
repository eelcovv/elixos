{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.thunderbird = {
    enable = true;
    profiles.default.isDefault = true;
  };

  accounts.email.accounts.eelco = {
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
}
