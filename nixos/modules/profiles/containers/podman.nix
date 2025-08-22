# nixos/modules/profiles/containers/podman.nix
{
  config,
  lib,
  pkgs,
  ...
}: {
  # Enable Podman and rootless container support
  virtualisation.podman = {
    enable = true;
    dockerCompat = true; # Provide a 'docker' shim for Podman
    defaultNetwork.settings.dns_enabled = true;

    # Useful helpers for rootless networking and overlay storage
    extraPackages = with pkgs; [
      fuse-overlayfs
      slirp4netns
      bubblewrap
      iptables
    ];

    # Automatically prune unused images/containers on a schedule
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  # Use overlay storage with fuse-overlayfs for rootless containers.
  # ignore_chown_errors helps avoid failures during ID-mapped layer copies
  # with certain images that contain special files (e.g., /etc/gshadow-).
  virtualisation.containers.storage.settings = {
    storage = {
      driver = "overlay";
      options = {
        mount_program = "${pkgs.fuse-overlayfs}/bin/fuse-overlayfs";
        ignore_chown_errors = "true";
      };
    };
  };

  # Ensure unprivileged user namespaces are available
  security.unprivilegedUsernsClone = true;

  # Provide a generous amount of user namespaces
  boot.kernel.sysctl."user.max_user_namespaces" = 15000;

  # Tools available on the host
  environment.systemPackages = with pkgs; [
    podman
    podman-compose
    fuse-overlayfs
    slirp4netns
  ];
}
