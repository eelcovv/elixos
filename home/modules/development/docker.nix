{
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    docker
    docker-buildx
    docker-compose
  ];

  virtualisation.docker.rootless.enable = true;
}
