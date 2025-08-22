{pkgs, ...}: {
  # User-level storage config for rootless Podman (per-user in ~/.config)
  xdg.configFile."containers/storage.conf".text = ''
    [storage]
    driver = "overlay"

    [storage.options]
    mount_program = "${pkgs.fuse-overlayfs}/bin/fuse-overlayfs"
    ignore_chown_errors = "true"
  '';
}
