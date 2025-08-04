{
  config,
  pkgs,
  ...
}: {
  environment.extraInit = ''
    export PATH=$PATH:${pkgs.util-linux}/bin:${pkgs.coreutils}/bin
  '';
}
