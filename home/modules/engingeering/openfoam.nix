# home/modules/engineering/openfoam.nix
{ config, lib, pkgs, ... }:

# Home Manager module that provides OpenFOAM helpers via Podman containers.
# It installs:
#   - of-shell : interactive OpenFOAM shell in the current directory
#   - of-run   : run a single OpenFOAM command non-interactively
#   - mkfoam   : create a .foam file for ParaView
#
# Requirements:
#   - Podman enabled at the system level (NixOS): virtualisation.podman.enable = true
#   - ParaView installed separately if you want to open *.foam files (in your default.nix)

let
  inherit (lib) mkEnableOption mkIf mkOption types;

  cfg = config.engineering.openfoam;

  # Construct the image reference once
  imageRef = "${cfg.image}:${cfg.tag}";

  # Shared podman run base (kept in one place for consistency)
  podmanBase = ''
    podman run --rm \
      --user $(id -u):$(id -g) \
      -v "$PWD":/case -w /case \
      ${imageRef}
  '';

  # Helper snippet for sourcing OpenFOAM env inside the container
  sourceOF = ''
    for p in \
      /usr/lib/openfoam/openfoam*/etc/bashrc \
      /opt/OpenFOAM-*/etc/bashrc \
      /opt/openfoam*/etc/bashrc \
      /usr/share/openfoam*/etc/bashrc \
      /usr/bin/openfoam \
    ; do
      if [ -f "$p" ]; then
        # shellcheck source=/dev/null
        source "$p" >/dev/null 2>&1 || true
        break
      fi
    done
  '';
in
{
  options.engineering.openfoam = {
    enable = mkEnableOption "OpenFOAM helpers (Podman-based)";

    # OpenCFD tags are typically like "2312", "2406", "2412"
    tag = mkOption {
      type = types.str;
      default = "2406";
      description = "OpenCFD OpenFOAM image tag (e.g., 2312, 2406, 2412).";
    };

    # Choose the image family (default = opencfd/openfoam-default)
    image = mkOption {
      type = types.str;
      default = "docker.io/opencfd/openfoam-default";
      description = "Container image base for OpenFOAM (e.g., opencfd/openfoam-default).";
    };
  };

  config = mkIf cfg.enable {
    # Ensure the Podman client is available in PATH for the user
    home.packages = [ pkgs.podman ];

    # of-shell: interactive OpenFOAM shell
    home.file.".local/bin/of-shell" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Interactive OpenFOAM shell inside the current directory (mounted at /case).
        # Usage: cd /path/to/case && of-shell
        set -euo pipefail
        exec ${podmanBase} bash -lc '
          ${sourceOF}
          echo "OpenFOAM ${cfg.tag} shell ready (working dir: /case)."
          echo "Examples: blockMesh; simpleFoam"
          exec bash -i
        '
      '';
    };

    # of-run: run a single OpenFOAM command without entering a shell
    home.file.".local/bin/of-run" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Run a single OpenFOAM command in the current directory non-interactively.
        # Usage: of-run blockMesh [-help]  |  of-run simpleFoam
        set -euo pipefail
        if [ $# -lt 1 ]; then
          echo "Usage: of-run <command> [args...]" >&2
          exit 2
        fi
        cmd="$*"
        ${podmanBase} bash -lc '
          ${sourceOF}
          echo "[of-run] '"$cmd"'"
          eval '"$cmd"'
        '
      '';
    };

    # mkfoam: create a .foam file for ParaView
    home.file.".local/bin/mkfoam" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Create a .foam file for ParaView to open the case directory directly.
        # Usage: mkfoam [name]  -> creates "<name>.foam" or "case.foam"
        set -euo pipefail
        name="${1:-case}"
        touch "${name}.foam"
        echo "Created: ${name}.foam (open in ParaView)."
      '';
    };
  };
}
