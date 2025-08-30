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
}
