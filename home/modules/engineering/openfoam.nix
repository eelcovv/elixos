{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption types;
  cfg = config.engineering.openfoam;
  scriptsDir = ../../scripts/openfoam;
in {
  options.engineering.openfoam = {
    enable = mkEnableOption "OpenFOAM helpers (containerized)";

    engine = mkOption {
      type = types.enum ["docker" "podman"];
      default = "docker";
      description = "Container engine to use for OpenFOAM helpers.";
    };

    # Choose ESI variant or your own (custom) image
    variant = mkOption {
      type = types.enum ["default" "dev" "custom"];
      default = "default";
      description = ''
        ESI image variant:
        - default -> docker.io/opencfd/openfoam-default:<tag>
        - dev     -> docker.io/opencfd/openfoam-dev:<tag>
        - custom  -> use `customImage` below
      '';
    };

    tag = mkOption {
      type = types.str;
      default = "2406";
      description = "OpenFOAM image tag (ESI).";
    };

    customImage = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Full image ref for custom builds (e.g. elx/openfoam-cfmesh:2406).";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      coreutils
      bashInteractive
      git
      gcc
      gnumake
      gnuplot
      pkg-config
      nodejs_22
      tree-sitter
    ];

    home.sessionPath = ["$HOME/.local/bin"];

    # Choose Image based on variant
    home.sessionVariables = let
      base =
        if cfg.variant == "default"
        then "docker.io/opencfd/openfoam-default"
        else if cfg.variant == "dev"
        then "docker.io/opencfd/openfoam-dev"
        else ""; # custom below
      image =
        if cfg.variant == "custom" && cfg.customImage != null
        then cfg.customImage
        else "${base}:${cfg.tag}";
    in {
      OPENFOAM_ENGINE = cfg.engine;
      OPENFOAM_IMAGE = image;
      OPENFOAM_TAG = cfg.tag; # alleen informatief
    };

    # Helper scripts
    home.file.".local/bin/of-shell" = {
      source = scriptsDir + "/of-shell";
      executable = true;
    };
    home.file.".local/bin/of-shell-root" = {
      source = scriptsDir + "/of-shell-root";
      executable = true;
    };
    home.file.".local/bin/of-run" = {
      source = scriptsDir + "/of-run";
      executable = true;
    };
    home.file.".local/bin/of-fix-perms" = {
      source = scriptsDir + "/of-fix-perms";
      executable = true;
    };
    home.file.".local/bin/mkfoam" = {
      source = scriptsDir + "/mkfoam";
      executable = true;
    };
    home.file.".local/bin/foamMPI" = {
      source = scriptsDir + "/foamMPI";
      executable = true;
    };
    home.file.".local/bin/vscode-of-shell" = {
      text = ''
        #!/usr/bin/env bash
        exec of-shell bash
      '';
      executable = true;
    };
  };
}
