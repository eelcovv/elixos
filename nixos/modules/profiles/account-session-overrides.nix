{
  config,
  lib,
  pkgs,
  ...
}: let
  # Filter alle gebruikers waarvoor een defaultSession is opgegeven
  usersWithSession =
    lib.filterAttrs
    (_name: _user: lib.hasAttr _name config.userMeta.defaultSession)
    config.users.users;

  # Genereer de inhoud van het accountsservice bestand per gebruiker
  sessionEtcEntries =
    lib.mapAttrs' (name: _user: {
      name = "accountsservice/users/${name}";
      value.text = ''
        [User]
        Session=${config.userMeta.defaultSession.${name}}
        SystemAccount=false
      '';
    })
    usersWithSession;

  # Genereer symlinks voor systemd-tmpfiles (van /var/lib/... → /etc/static/...)
  tmpfileRules =
    lib.mapAttrsToList
    (
      name: _: "L+ /var/lib/AccountsService/users/${name} - - - - /etc/static/accountsservice/users/${name}"
    )
    usersWithSession;
in {
  environment.etc = sessionEtcEntries;

  systemd.tmpfiles.rules = tmpfileRules;
}
