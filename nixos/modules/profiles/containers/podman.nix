# nixos/modules/profiles/containers/podman.nix
{
  config,
  lib,
  pkgs,
  ...
}: {
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;

    # Handig, maar optioneel:
    autoPrune = {
      enable = true;
      dates = "weekly";
    };

    # Zorg dat rootless alle helpers heeft
    extraPackages = with pkgs; [
      fuse-overlayfs
      slirp4netns
      iptables # vaak al aanwezig, maar zeker voor rootless netwerken
      bubblewrap
    ];
  };

  # Forceer overlay storage met fuse-overlayfs als mount-program
  virtualisation.containers.storage.settings = {
    storage = {
      driver = "overlay";
      options = {
        mount_program = "${pkgs.fuse-overlayfs}/bin/fuse-overlayfs";
        # Als je toch nog chown-foutjes ziet bij exotische images:
        # ignore_chown_errors = "true";
      };
    };
  };

  # (meestal al true, maar expliciet kan geen kwaad)
  security.unprivilegedUsernsClone = true;

  # Voor de zekerheid voldoende namespaces
  boot.kernel.sysctl."user.max_user_namespaces" = 15000;

  environment.systemPackages = with pkgs; [
    podman
    podman-compose
    fuse-overlayfs
    slirp4netns
  ];
}
