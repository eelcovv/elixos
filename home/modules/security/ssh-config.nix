{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    matchBlocks = {
      "github.com" = {
        hostname = "ssh.github.com";
        user = "git";
        port = 443;
        identityFile = ["~/.ssh/id_ed25519"];
        identitiesOnly = true;
      };

      "github-443" = {
        hostname = "ssh.github.com";
        user = "git";
        port = 443;
        identityFile = ["~/.ssh/id_ed25519"];
        identitiesOnly = true;
      };

      "github-22" = {
        hostname = "github.com";
        user = "git";
        port = 22;
        identityFile = ["~/.ssh/id_ed25519"];
        identitiesOnly = true;
      };

      "contabo" = {
        hostname = "194.146.13.222";
        user = "eelco";
        identityFile = ["~/.ssh/id_ed25519"];
        identitiesOnly = true;
      };

      "contaboroot" = {
        hostname = "194.146.13.222";
        user = "root";
        identityFile = ["~/.ssh/id_ed25519"];
        identitiesOnly = true;
      };

      "*" = {
        forwardAgent = false;
        addKeysToAgent = "no";
        compression = false;
        serverAliveInterval = 15;
        serverAliveCountMax = 2;
        hashKnownHosts = false;
        userKnownHostsFile = "~/.ssh/known_hosts";
        controlMaster = "no";
        controlPath = "~/.ssh/master-%r@%n:%p";
        controlPersist = "no";
        identityFile = ["~/.ssh/id_ed25519"];
        identitiesOnly = true;

        # Options that do not (yet) have a dedicated HM option
        extraOptions = {
          ConnectTimeout = "8";
          IPQoS = "none";
        };
      };
    };
  };
}
