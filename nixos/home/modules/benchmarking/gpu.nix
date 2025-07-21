{ config, pkgs, lib, ... }:

{
  options = { };
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
    home.sessionPath = [ "$HOME/.local/bin" ];

    # Optioneel: voorbereid scriptmapje maken
    home.file.".local/bin/run-gpu-benchmarks".text = ''
      #!/bin/sh
      set -e

      echo "=== GLMark2 (OpenGL) benchmark ==="
      glmark2 -f || echo "glmark2 faalde"

      echo
      echo "=== VkMark (Vulkan) benchmark ==="
      vkmark || echo "vkmark faalde"

      echo
      echo "Klaar met GPU-benchmarks."
    '';
    home.file.".local/bin/run-gpu-benchmarks".executable = true;
  };
}
