{
  config,
  lib,
  pkgs,
  ...
}: let
  # Filter alle gebruikers met een defaultSession attribuut
  usersWithSession =
    lib.filterAttrs (_name: user: user ? defaultSession) config.users.users;

  # Maak voor elke gebruiker een environment.etc entry
  sessionEtcEntries =
    lib.mapAttrs' (name: user: {
      name = "accountsservice/users/${name}";
      value.text = ''
        [User]
        Session=${user.defaultSession}
      '';
    })
    usersWithSession;
in {
  environment.etc = sessionEtcEntries;
}
