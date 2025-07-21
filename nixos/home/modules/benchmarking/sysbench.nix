{ config, pkgs, lib, ... }:

{
  home.packages = [ pkgs.sysbench ];

  home.file.".local/bin/run-sysbench-cpu".text = ''
    #!/bin/sh
    sysbench cpu --cpu-max-prime=20000 run
