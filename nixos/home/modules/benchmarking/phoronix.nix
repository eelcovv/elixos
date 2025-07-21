{ config, pkgs, lib, ... }:

{
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

  home.activation.installPhoronixConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.phoronix-test-suite"
    cp ${pkgs.writeText "user-config.xml" ''
      <?xml version="1.0"?>
      <PhoronixTestSuite>
        <Options>
          <SaveResults>FALSE</SaveResults>
          <OpenBrowser>FALSE</OpenBrowser>
          <UploadResults>FALSE</UploadResults>
          <PromptForTestDescription>FALSE</PromptForTestDescription>
          <PromptSaveName>FALSE</PromptSaveName>
          <RunAllTestCombinations>FALSE</RunAllTestCombinations>
          <RunAllTestIterations>FALSE</RunAllTestIterations>
          <PromptSaveIdentifier>FALSE</PromptSaveIdentifier>
        </Options>
      </PhoronixTestSuite>
    ''} "$HOME/.phoronix-test-suite/user-config.xml"
  '';
}
