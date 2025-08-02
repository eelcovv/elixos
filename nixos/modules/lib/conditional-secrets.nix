{
  config,
  lib,
  options,
  ...
}: let
  inherit (lib) filterAttrs trace;

  # De originele (niet-gefilterde) secrets zoals gedefinieerd in modules
  allSecrets = options.sops.secrets.default;

  # Helper: check of een gebruiker bestaat
  hasUser = user:
    user != null && config.users.users ? user;

  # Filter secrets met trace bij ontbrekende gebruikers
  filteredSecrets =
    filterAttrs (
      name: val: let
        user = val.owner or null;
      in
        if hasUser user
        then true
        else trace "🔒 Skipping secret `${name}` because user `${toString user}` does not exist at evaluation time." false
    )
    allSecrets;
in {
  config.sops.secrets = filteredSecrets;
}
