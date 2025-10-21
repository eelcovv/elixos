# home/modules/development/pypi.nix
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.pypi;
in {
  options.pypi = {
    enable = lib.mkEnableOption "Generate ~/.pypirc from system-level sops secrets in /run/secrets";

    tokenPaths = {
      main = lib.mkOption {
        type = lib.types.str;
        default = "/run/secrets/pypi_token_main";
        description = "Path to the main PyPI API token (used with username=__token__).";
      };
      davelab = lib.mkOption {
        type = lib.types.str;
        default = "/run/secrets/pypi_token_davelab";
        description = "Optional DaveLab API token (used when davelab.auth.mode = \"token\").";
      };
    };

    testpypi = {
      enable = lib.mkEnableOption "Add a 'testpypi' index entry to ~/.pypirc";
      tokenPath = lib.mkOption {
        type = lib.types.str;
        default = config.sops.secrets.pypi_token_testpypi.path;
        description = "Path to the TestPyPI API token (used with username=__token__).";
      };
    };

    davelab = {
      enable = lib.mkEnableOption "Add a 'davelab' index entry to ~/.pypirc";

      repository = lib.mkOption {
        type = lib.types.str;
        default = "https://pypi.davelab.eu/legacy/";
        description = "Upload URL for the DaveLab private index.";
      };

      auth = {
        mode = lib.mkOption {
          type = lib.types.enum ["token" "basic"];
          default = "token";
          description = ''
            Authentication mode for the DaveLab index:
            - "token":   use API token with username="__token__"
            - "basic":   use username/password from /run/secrets files
          '';
        };
        usernamePath = lib.mkOption {
          type = lib.types.str;
          default = "/run/secrets/davelab_username";
          description = "Path to the DaveLab username file (when auth.mode = \"basic\").";
        };
        passwordPath = lib.mkOption {
          type = lib.types.str;
          default = "/run/secrets/davelab_password";
          description = "Path to the DaveLab password file (when auth.mode = \"basic\").";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable (
    let
      homeDir = config.home.homeDirectory;
      user = config.home.username;

      generateScript = ''
        set -eu

        main="${lib.escapeShellArg cfg.tokenPaths.main}"
        dlabToken="${lib.escapeShellArg cfg.tokenPaths.davelab}"
        dlabUserPath="${lib.escapeShellArg cfg.davelab.auth.usernamePath}"
        dlabPassPath="${lib.escapeShellArg cfg.davelab.auth.passwordPath}"
        testpypiTokenPath="${lib.escapeShellArg cfg.testpypi.tokenPath}"

        outfile="${lib.escapeShellArg "${homeDir}/.pypirc"}"

        if [ ! -r "$main" ]; then
          echo "[pypi.nix] WARN: $main not readable; skipping .pypirc generation" >&2
          exit 0
        fi

        pypi_pass="$(cat "$main")"

        testpypi_pass=""
        if ${lib.boolToString cfg.testpypi.enable}; then
          if [ -r "$testpypiTokenPath" ]; then
            testpypi_pass="$(cat "$testpypiTokenPath")"
          fi
        fi

        dlab_user="__token__"
        dlab_pass="$pypi_pass"

        if ${lib.boolToString cfg.davelab.enable}; then
          case "${lib.escapeShellArg cfg.davelab.auth.mode}" in
            "basic")
              dlab_user="$([ -r "$dlabUserPath" ] && cat "$dlabUserPath" || echo "")"
              dlab_pass="$([ -r "$dlabPassPath" ] && cat "$dlabPassPath" || echo "")"
              ;;
            "token")
              if [ -r "$dlabToken" ]; then
                dlab_pass="$(cat "$dlabToken")"
              fi
              dlab_user="__token__"
              ;;
          esac
        fi

        umask 177
        tmp="$(mktemp)"

        {
          echo "[distutils]"
          echo "index-servers ="
          echo "    pypi"
          if ${lib.boolToString cfg.davelab.enable}; then
            echo "    davelab"
          fi
          if ${lib.boolToString cfg.testpypi.enable}; then
            echo "    testpypi"
          fi

          echo
          echo "[pypi]"
          echo "username = __token__"
          echo "password = $pypi_pass"

          if ${lib.boolToString cfg.davelab.enable}; then
            echo
            echo "[davelab]"
            echo "repository = ${cfg.davelab.repository}"
            echo "username = $dlab_user"
            echo "password = $dlab_pass"
          fi

          if ${lib.boolToString cfg.testpypi.enable} && [ -n "$testpypi_pass" ]; then
            echo
            echo "[testpypi]"
            echo "username = __token__"
            echo "password = $testpypi_pass"
          fi
        } > "$tmp"

        install -m 0600 -o ${lib.escapeShellArg user} -g users "$tmp" "$outfile"
        rm -f "$tmp"
        echo "[pypi.nix] Wrote $outfile"
      '';
    in {
      home.packages = [pkgs.twine];
      home.activation.pypiPypirc =
        lib.hm.dag.entryAfter ["writeBoundary"] generateScript;
    }
  );
}
