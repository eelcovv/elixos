{
  config,
  pkgs,
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
    flavor = "imap";
    imap = {
      host = "mail.davelab.nl";
      port = 993;
      tls = true;
    };
    smtp = {
      host = "mail.davelab.nl";
      port = 587;
      tls = true;
    };
    thunderbird.enable = true;
  };
}
