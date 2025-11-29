{
  config,
  pkgs,
  lib,
  ...
}: {
  options = {};
  config = {
    home.packages = [
      # GPU benchmarks
      pkgs.glmark2
      pkgs.vkmark

      # Systeemhulpmiddelen
      pkgs.lm_sensors
      pkgs.pciutils
    ];

    # Zet ~/.local/bin in je PATH voor eventuele scripts
    home.sessionPath = ["$HOME/.local/bin"];

    # Optioneel: voorbereid scriptmapje maken
    home.file.".local/bin/run-gpu-benchmarks".text = ''
      #!/bin/sh
      set -e

      echo "=== GLMark2 (OpenGL) benchmark ==="
      glmark2 --fullscreen || echo "glmark2 failure"

      echo
      echo "=== VkMark (Vulkan) benchmark ==="
      vkmark || echo "vKark failed"

      echo
      echo "Ready with GPU benchmarks. "
    '';
    home.file.".local/bin/run-gpu-benchmarks".executable = true;
  };
}
