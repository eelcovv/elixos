{
  config,
  pkgs,
  lib,
  ...
}: {
  home.packages = [pkgs.stress-ng];

  home.file.".local/bin/run-stress-memory".text = ''
    #!/bin/sh
    stress-ng --vm 2 --vm-bytes 1G --timeout 60s
  '';
  home.file.".local/bin/run-stress-memory".executable = true;
}
