{
  config,
  lib,
  pkgs,
  ...
}: {
  # Generate ~/.ssh/config from this text
  programs.ssh.enable = true;
  programs.ssh.extraConfig = ''
    # ~/.ssh/config
    # -----------------------------------------------------------------------------
    # Global defaults
    # -----------------------------------------------------------------------------
    Host *
      IdentityFile ~/.ssh/id_ed25519
      IdentitiesOnly yes
      ConnectTimeout 8
      ServerAliveInterval 15
      ServerAliveCountMax 2
      IPQoS none
      Port 22

    # -----------------------------------------------------------------------------
    # Contabo
    # -----------------------------------------------------------------------------
    Host contabo
      HostName 194.146.13.222
      User eelco

    Host contaboroot
      HostName 194.146.13.222
      User root

    # -----------------------------------------------------------------------------
    # GitHub
    # -----------------------------------------------------------------------------
    # Use port 443 to keep SSH connections stable when using a VPN.
    Host github.com
      HostName ssh.github.com
      Port 443
      User git

    Host github-443
      HostName ssh.github.com
      Port 443
      User git

    Host github-22
      HostName github.com
      Port 22
      User git
  '';
}
