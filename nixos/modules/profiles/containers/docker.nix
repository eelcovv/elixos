# nixos/modules/docker.nix (system-level)
{
  config,
  pkgs,
  ...
}: {
  # Start de Docker daemon (rootful)
  virtualisation.docker.enable = true;

  # Optioneel: extra daemon settings (voorbeeld)
  # virtualisation.docker.daemon.settings = {
  #   features = { buildkit = true; };
  # };

  # Zorg dat compose en buildx beschikbaar zijn (handig ook buiten HM)
  environment.systemPackages = with pkgs; [
    docker-compose
    docker-buildx
  ];

  # Je had dit al ergens staan, maar voor de volledigheid:
  users.users.eelco.extraGroups = ["docker"];
}
