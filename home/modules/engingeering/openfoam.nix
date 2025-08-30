# home/modules/engineering/openfoam.nix
{ config, pkgs, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf mkOption types;

  cfg = config.engineering.openfoam;

  imageRef = "${cfg.image}:${cfg.tag}";

  engineBin =
    if cfg.engine == "podman" then "podman" else "docker";

  # Bash snippet to source any OpenFOAM bashrc
  sourceOF = ''
    for p in /usr/lib/openfoam/openfoam*/etc/bashrc \
             /opt/OpenFOAM-*/etc/bashrc \
             /opt/openfoam*/etc/bashrc \
             /usr/share/openfoam*/etc/bashrc \
             /usr/bin/openfoam; do
      if [ -f "$p" ]; then
        # suppress noisy output
        # shellcheck disable=SC1090
        source "$p" >/dev/null 2>&1 || true
        break
      fi
    done
  '';

  basePkgs = [ pkgs.coreutils pkgs.bashInteractive ];
  dockerPkgs = if cfg.engine == "docker" then [ pkgs.docker ] else [ ];
  podmanPkgs = if cfg.engine == "podman" then [ pkgs.podman ] else [ ];
in
{
  options.engineering.openfoam = {
    enable = mkEnableOption "OpenFOAM helpers (containerized)";

    engine = mkOption {
      type = types.enum [ "docker" "podman" ];
      default = "docker";
      description = "Container engine to use for OpenFOAM helpers.";
    };

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

  config = mkIf cfg.enable {
    home.packages = basePkgs ++ dockerPkgs ++ podmanPkgs;

    # Interactive shell as current user (keeps file ownership)
    home.file.".local/bin/of-shell" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        set -euo pipefail
        uid=$(id -u)
        gid=$(id -g)
        exec ${engineBin} run --rm -it \
          --user "${uid}:${gid}" \
          -v "$PWD":/case -w /case \
          ${imageRef} \
          bash -lc '${sourceOF}
            cd /case || exit 1
            echo "[of-shell] cwd=$(pwd), uid=$(id -u), gid=$(id -g)"
            exec bash -i'
      '';
    };

    # Interactive shell as root in container
    home.file.".local/bin/of-shell-root" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        set -euo pipefail
        exec ${engineBin} run --rm -it \
          --user 0:0 \
          -v "$PWD":/case -w /case \
          ${imageRef} \
          bash -lc '${sourceOF}
            cd /case || exit 1
            echo "[of-shell-root] cwd=$(pwd), uid=$(id -u), gid=$(id -g)"
            exec bash -i'
      '';
    };

    # Run a single OpenFOAM command (as current user)
    home.file.".local/bin/of-run" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        set -euo pipefail
        if [ $# -lt 1 ]; then
          echo "Usage: of-run <command> [args...]" >&2
          exit 2
        fi
        uid=$(id -u)
        gid=$(id -g)
        cmd="$*"
        exec ${engineBin} run --rm \
          --user "${uid}:${gid}" \
          -v "$PWD":/case -w /case \
          ${imageRef} \
          bash -lc '${sourceOF}
            cd /case || exit 1
            echo "[of-run] '"$cmd"'"
            eval '"$cmd"''
      '';
    };

    # Fix ownership when you used root-in-container
    home.file.".local/bin/of-fix-perms" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        set -euo pipefail
        user_id=$(id -u)
        group_id=$(id -g)
        echo "Chowning $(pwd) recursively to ${user_id}:${group_id} ..."
        chmod -R u+rwX,g+rwX .
        chown -R "${user_id}:${group_id}" .
        echo "Done."
      '';
    };

    # ParaView helper
    home.file.".local/bin/mkfoam" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        set -euo pipefail
        name="${1:-case}"
        touch "${name}.foam"
        echo "Created: ${name}.foam (open in ParaView)."
      '';
    };
  };
}

