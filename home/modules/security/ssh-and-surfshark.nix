{
  config,
  lib,
  pkgs,
  ...
}: {
  # ~/.ssh/config (with comments)
  home.file.".ssh/config" = {
    text = ''
      # ~/.ssh/config
      # -----------------------------------------------------------------------------
      # Global defaults (apply to all hosts)
      # -----------------------------------------------------------------------------
      Host *
        IdentityFile ~/.ssh/id_ed25519     # your SSH key
        IdentitiesOnly yes                  # force only this key
        ConnectTimeout 8                    # fail fast on network issues
        ServerAliveInterval 15              # keep connection alive
        ServerAliveCountMax 2
        IPQoS none                          # avoid QoS throttling/drops on some networks

      # -----------------------------------------------------------------------------
      # GitHub: default via port 443 (reliable; works behind VPN/firewalls)
      # Use repo URLs like: git@github.com:OWNER/REPO.git
      # -----------------------------------------------------------------------------
      Host github.com
        HostName ssh.github.com
        Port 443
        User git

      # -----------------------------------------------------------------------------
      # Alias: explicit 443 (useful for testing or per-repo usage)
      # Example repo URL: git@github-443:OWNER/REPO.git
      # -----------------------------------------------------------------------------
      Host github-443
        HostName ssh.github.com
        Port 443
        User git

      # -----------------------------------------------------------------------------
      # Alias: classic port 22 (use only if you really need this)
      # Example repo URL: git@github-22:OWNER/REPO.git
      # -----------------------------------------------------------------------------
      Host github-22
        HostName github.com
        Port 22
        User git
    '';
    mode = "0600";
  };

  # ~/.config/surfshark-endpoints (NO comments; parser expects key=value only)
  # Format: <short-name>=<endpoint:port>
  # Example keys below match your usage: bk, sg, nl
  xdg.configFile."surfshark-endpoints" = {
    text = ''
      bk=th-bkk.prod.surfshark.com:51820
      sg=sg-sng.prod.surfshark.com:51820
      nl=143.244.42.89:51820
    '';
    mode = "0644";
  };
}
