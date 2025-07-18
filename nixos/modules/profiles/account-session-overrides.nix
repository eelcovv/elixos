{
  config,
  lib,
  pkgs,
  ...
}: let
  usersWithSession =
    lib.filterAttrs (
      _name: _:
        lib.hasAttrByPath ["userMeta" "defaultSession"] config
        && lib.hasAttr _name config.userMeta.defaultSession
    )
    config.users.users;

  sessionEtcEntries =
    lib.mapAttrs' (name: _: {
      name = "accountsservice/users/${name}";
      value.text = ''
        [User]
        Session=${config.userMeta.defaultSession.${name}}
      '';
    })
    usersWithSession;
in {
  environment.etc = sessionEtcEntries;
}
