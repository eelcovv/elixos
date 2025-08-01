{
  config,
  lib,
  ...
}: let
  inherit (lib) mapAttrs filterAttrs trace;

  # Helper: check of een gebruiker bestaat
  hasUser = user:
    user != null && config.users.users ? "${user}";

  # Filter secrets en log welke overgeslagen worden
  filteredSecrets =
    filterAttrs (
      name: val: let
        user = val.owner or null;
      in
        if hasUser user
        then true
        else trace "🔒 Skipping secret `${name}` because user `${toString user}` does not exist at evaluation time." false
    )
    config.sops.secrets;
in {
  config.sops.secrets = filteredSecrets;
}
