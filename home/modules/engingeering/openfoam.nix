# home/modules/engingeering/openfoam.nix
{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption types;
  cfg = config.engineering.openfoam;

  # Full image reference (OpenCFD official image)
  imageRef = "${cfg.image}:${cfg.tag}";
in {
  # -----------------------------
  # Module options
  # -----------------------------
  options.engineering.openfoam = {
    enable = mkEnableOption "OpenFOAM helpers (Podman-based)";

    tag = mkOption {
      type = types.str;
      default = "2406";
      description = "OpenCFD OpenFOAM image tag (e.g., 2312, 2406, 2412).";
    };

    image = mkOption {
      type = types.str;
      default = "docker.io/opencfd/openfoam-default";
      description = "Container image base for OpenFOAM.";
    };
  };

  # -----------------------------
  # Implementation
  # -----------------------------
  config = mkIf cfg.enable {
    # Tools in PATH
    home.packages = with pkgs; [
      podman
      coreutils
      bashInteractive
    ];

    # of-shell: run as root in the container for maximum compatibility
    home.file.".local/bin/of-shell" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Interactive OpenFOAM shell (root in container). Simple and reliable.
        # NOTE: files created in /case will be owned by root:root on the host.
        #       Use 'of-fix-perms' afterwards if needed.
        set -euo pipefail
        exec podman run --rm -it \
          --user 0:0 \
          -v "$PWD":/case -w /case \
          ${imageRef} \
          bash -lc 'for p in /usr/lib/openfoam/openfoam*/etc/bashrc /opt/OpenFOAM-*/etc/bashrc /opt/openfoam*/etc/bashrc /usr/share/openfoam*/etc/bashrc /usr/bin/openfoam; do if [ -f "$p" ]; then source "$p" >/dev/null 2>&1 || true; break; fi; done; cd /case || exit 1; echo "[of-shell] cwd=$(pwd), uid=$(id -u), gid=$(id -g)"; exec bash -i'
      '';
    };

    # of-run: run a single OpenFOAM command (root in container)
    home.file.".local/bin/of-run" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Run an OpenFOAM command in the current directory (root in container).
        # NOTE: files created in /case will be owned by root:root on the host.
        set -euo pipefail
        if [ $# -lt 1 ]; then
          echo "Usage: of-run <command> [args...]" >&2
          exit 2
        fi
        cmd="$*"
        exec podman run --rm \
          --user 0:0 \
          -v "$PWD":/case -w /case \
          ${imageRef} \
          bash -lc "for p in /usr/lib/openfoam/openfoam*/etc/bashrc /opt/OpenFOAM-*/etc/bashrc /opt/openfoam*/etc/bashrc /usr/share/openfoam*/etc/bashrc /usr/bin/openfoam; do if [ -f \"\$p\" ]; then source \"\$p\" >/dev/null 2>&1 || true; break; fi; done; cd /case || exit 1; echo \"[of-run] \$cmd\"; eval \$cmd"
      '';
    };

    # of-fix-perms: convenience helper to chown the current case back to your user
    home.file.".local/bin/of-fix-perms" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Fix ownership of files created by root-in-container to the current user.
        # Usage: run from your case directory after container work.
        set -euo pipefail
        user_id=$(id -u)
        group_id=$(id -g)
        echo "Chowning $(pwd) recursively to ''${user_id}:''${group_id} ..."
        chown -R "''${user_id}:''${group_id}" .
        echo "Done."
      '';
    };

    # mkfoam: tiny helper for ParaView
    home.file.".local/bin/mkfoam" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Create a .foam file for ParaView to open the case directory directly.
        set -euo pipefail
        name="''${1:-case}"
        touch "''${name}.foam"
        echo "Created: ''${name}.foam (open in ParaView)."
      '';
    };
  };
}
