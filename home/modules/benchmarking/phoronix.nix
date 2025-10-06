{
  config,
  pkgs,
  lib,
  ...
}: {
  home.packages = [
    pkgs.phoronix-test-suite
    pkgs.firefox
    pkgs.google-chrome
  ];

  home.file.".local/bin/run-benchmarks".text = ''
    #!/bin/sh
    set -e

    TIMESTAMP=$(date +%F_%H-%M)
    OUTDIR="$HOME/benchmarks/$TIMESTAMP"
    mkdir -p "$OUTDIR"

    echo "Benchmarkresultaten worden opgeslagen in: $OUTDIR"

    # Installeer benodigde tests vooraf
    phoronix-test-suite install \
      pts/cpuinfo \
      pts/compress-7zip \
      pts/memory \
      pts/motionmark \
      pts/jetstream \
      pts/octane \
      pts/glmark2

    # Draai batch benchmark
    phoronix-test-suite batch-run \
      pts/cpuinfo \
      pts/compress-7zip \
      pts/memory \
      pts/motionmark \
      pts/jetstream \
      pts/octane \
      pts/glmark2 \
      | tee "$OUTDIR/output.txt"
  '';
  home.file.".local/bin/run-benchmarks".executable = true;
}
