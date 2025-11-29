{ lib, config, ... }:

let
  cfg = config.elx.pypi;
in
{
  options.elx.pypi = {
    # Welke gebruiker moet /run/secrets/* mogen lezen?
    user = lib.mkOption {
      type = lib.types.str;
      default = "eelco";
      description = "Owner (UNIX user) of the PyPI/DaveLab secrets in /run/secrets.";
    };

    # Paden naar jouw drie sops-bestanden
    files = {
      mainFile = lib.mkOption {
        type = lib.types.path;
        default = ../../secrets/pypi/token_eelco.yaml;
        description = "SOPS file with the main PyPI token.";
      };
      testFile = lib.mkOption {
        type = lib.types.path;
        default = ../../secrets/pypi/testpypi_token_eelco.yaml;
        description = "SOPS file with the TestPyPI token.";
      };
      davelabFile = lib.mkOption {
        type = lib.types.path;
        default = ../../secrets/pypi/davelab_eelco.yaml;
        description = "SOPS file with DaveLab credentials (username/password).";
      };
    };

    # Keys (YAML sleutelnamen) ín die bestanden
    keys = {
      mainKey = lib.mkOption {
        type = lib.types.str;
        default = "pypi_token";
        description = "YAML key inside mainFile containing the PyPI token.";
      };
      testKey = lib.mkOption {
        type = lib.types.str;
        default = "testpypi_token";
        description = "YAML key inside testFile containing the TestPyPI token.";
      };
      usernameKey = lib.mkOption {
        type = lib.types.str;
        default = "username";
        description = "YAML key inside davelabFile containing the DaveLab username.";
      };
      passwordKey = lib.mkOption {
        type = lib.types.str;
        default = "password";
        description = "YAML key inside davelabFile containing the DaveLab password.";
      };
    };

    # Schakelaars (kun je uitzetten als een host iets niet nodig heeft)
    enableTestPyPI = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Expose TestPyPI token as /run/secrets/pypi_token_testpypi.";
    };
    enableDaveLabBasic = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Expose DaveLab basic-auth credentials (/run/secrets/davelab_username, /run/secrets/davelab_password).";
    };
  };

  config = {
    # Main PyPI token -> /run/secrets/pypi_token_main
    sops.secrets."pypi_token_main" = {
      sopsFile = cfg.files.mainFile;
      key = cfg.keys.mainKey;
      owner = cfg.user;
      group = "users";
      mode = "0400";
    };

    # TestPyPI token -> /run/secrets/pypi_token_testpypi
    #sops.secrets."pypi_token_testpypi" = lib.mkIf cfg.enableTestPyPI {
    #  sopsFile = cfg.files.testFile;
    #  key = cfg.keys.testKey;
    #  owner = cfg.user;
    #  group = "users";
    #  mode = "0400";
    #};

    # DaveLab basic auth -> /run/secrets/davelab_username + /run/secrets/davelab_password
    sops.secrets."davelab_username" = lib.mkIf cfg.enableDaveLabBasic {
      sopsFile = cfg.files.davelabFile;
      key = cfg.keys.usernameKey;
      owner = cfg.user;
      group = "users";
      mode = "0400";
    };
    sops.secrets."davelab_password" = lib.mkIf cfg.enableDaveLabBasic {
      sopsFile = cfg.files.davelabFile;
      key = cfg.keys.passwordKey;
      owner = cfg.user;
      group = "users";
      mode = "0400";
    };
  };
}

