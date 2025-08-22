# home/modules/engingeering/openfoam.nix
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption types;

  cfg = config.engineering.openfoam;

  # Full image reference once
  imageRef = "${cfg.image}:${cfg.tag}";

  # Rootless run args: keep host uid/gid inside container
  runBase = ''
    podman run --rm \
      --userns=keep-id \
      --user $(id -u):$(id -g) \
      -v "$PWD":/case -w /case \
      ${imageRef}
  '';

  # Interactive variant (-it) for TTY sessions
  runInteractive = ''
    podman run --rm -it \
      --userns=keep-id \
      --user $(id -u):$(id -g) \
      -v "$PWD":/case -w /case \
      ${imageRef}
  '';

  # Best-effort: source OpenFOAM environment inside the container
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
in {
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
      description = "Container image base for OpenFOAM (e.g., opencfd/openfoam-default).";
    };
  };

  config = mkIf cfg.enable {
    # Ensure Podman client is in PATH for the user
    home.packages = [pkgs.podman];

    # of-shell: interactive OpenFOAM shell in the current directory
    home.file.".local/bin/of-shell" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Interactive OpenFOAM shell inside the current directory (mounted at /case).
        # Usage: cd /path/to/case && of-shell
        set -euo pipefail
        exec ${runInteractive} bash -lc '
          ${sourceOF}
          cd /case || exit 1
          echo "OpenFOAM ${cfg.tag} shell ready (cwd: $(pwd))."
          exec bash -i
        '
      '';
    };

    # of-run: run a single OpenFOAM command non-interactively
    home.file.".local/bin/of-run" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Run a single OpenFOAM command in the current directory.
        # Usage: of-run blockMesh | of-run simpleFoam
        set -euo pipefail
        if [ $# -lt 1 ]; then
          echo "Usage: of-run <command> [args...]" >&2
          exit 2
        fi
        cmd="$*"
        ${runBase} bash -lc '
          ${sourceOF}
          cd /case || exit 1
          echo "[of-run] '"$cmd"'"
          eval '"$cmd"'
        '
      '';
    };

    # mkfoam: create a .foam file for ParaView post-processing
    home.file.".local/bin/mkfoam" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Create a .foam file for ParaView to open the case directory directly.
        # Usage: mkfoam [name]  -> creates "<name>.foam" or "case.foam"
        set -euo pipefail
        name="''${1:-case}"
        touch "''${name}.foam"
        echo "Created: ''${name}.foam (open in ParaView)."
      '';
    };
  };
}
