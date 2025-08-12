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
    # Specific hosts first, so their settings are not overridden by Host *
    # -----------------------------------------------------------------------------

    # GitHub via 443 (stable connection when using a VPN)
    Host github.com
      HostName ssh.github.com
      User git
      Port 443
      IdentityFile ~/.ssh/id_ed25519
      IdentitiesOnly yes

    # GitHub alias via 443
    Host github-443
      HostName ssh.github.com
      User git
      Port 443
      IdentityFile ~/.ssh/id_ed25519
      IdentitiesOnly yes

    # GitHub via standard SSH port (22)
    Host github-22
      HostName github.com
      User git
      Port 22
      IdentityFile ~/.ssh/id_ed25519
      IdentitiesOnly yes

    # Contabo (user eelco)
    Host contabo
      HostName 194.146.13.222
      User eelco
      IdentityFile ~/.ssh/id_ed25519
      IdentitiesOnly yes

    # Contabo (root)
    Host contaboroot
      HostName 194.146.13.222
      User root
      IdentityFile ~/.ssh/id_ed25519
      IdentitiesOnly yes

    # -----------------------------------------------------------------------------
    # Global defaults (applied to all hosts, only if not overridden above)
    # -----------------------------------------------------------------------------
    Host *
      ForwardAgent no
      AddKeysToAgent no
      Compression no
      ServerAliveInterval 15
      ServerAliveCountMax 2
      HashKnownHosts no
      UserKnownHostsFile ~/.ssh/known_hosts
      ControlMaster no
      ControlPath ~/.ssh/master-%r@%n:%p
      ControlPersist no
      IdentityFile ~/.ssh/id_ed25519
      IdentitiesOnly yes
      ConnectTimeout 8
      IPQoS none
      # Note: No Port here, so host-specific ports (like GitHub 443) take effect
  '';
}
