{
  config,
  pkgs,
  lib,
  ...
}: {
  home.packages = [pkgs.fio];

  home.file.".local/bin/run-fio-disk".text = ''
    #!/bin/sh
    fio --name=write --filename=tempfile --size=512M --bs=4k --rw=write --iodepth=1 --direct=1
  '';
  home.file.".local/bin/run-fio-disk".executable = true;
}
