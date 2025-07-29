{
  config,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    coreutils
    util-linux
    iproute2
    openssh
    shadow
  ];
}
