# home/modules/engineering/openfoam.nix
{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption types;

  cfg = config.engineering.openfoam;

  # Relatief pad naar de scriptsmap, vanaf dit bestand:
  scriptsDir = ../../scripts/openfoam;
in {
  options.engineering.openfoam = {
    enable = mkEnableOption "OpenFOAM helpers (containerized)";

    engine = mkOption {
      type = types.enum ["docker" "podman"];
      default = "docker";
      description = "Container engine to use for OpenFOAM helpers.";
    };

    image = mkOption {
      type = types.str;
      default = "docker.io/opencfd/openfoam-default";
      description = "Container image reference (without tag).";
    };

    tag = mkOption {
      type = types.str;
      default = "2406";
      description = "OpenFOAM image tag.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [pkgs.coreutils pkgs.bashInteractive pkgs.docker];

    home.sessionVariables = {
      OPENFOAM_ENGINE = cfg.engine;
      OPENFOAM_IMAGE = cfg.image;
      OPENFOAM_TAG = cfg.tag;
    };

    home.file.".local/bin/of-shell".source = scriptsDir + "/of-shell.sh";
    home.file.".local/bin/of-shell-root".source = scriptsDir + "/of-shell-root.sh";
    home.file.".local/bin/of-run".source = scriptsDir + "/of-run.sh";
    home.file.".local/bin/of-fix-perms".source = scriptsDir + "/of-fix-perms.sh";
    home.file.".local/bin/mkfoam".source = scriptsDir + "/mkfoam.sh";
  };
}
