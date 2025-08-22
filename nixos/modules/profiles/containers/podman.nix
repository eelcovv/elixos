# nixos/modules/profiles/containers/podman.nix
{
  config,
  lib,
  pkgs,
  ...
}: {
  # Enable Podman as container runtime
  virtualisation.podman = {
    enable = true;
    dockerCompat = true; # Provide a 'docker' alias to Podman
    defaultNetwork.settings.dns_enabled = true;
    autoPrune = {
      enable = true; # Automatically prune unused images/containers
      dates = "weekly";
    };
  };

  # Add Podman tools to system packages
  environment.systemPackages = with pkgs; [
    podman
    podman-compose
  ];

  # Configure default registries for Podman
  virtualisation.containers.registries.search = ["docker.io" "quay.io"];
}
