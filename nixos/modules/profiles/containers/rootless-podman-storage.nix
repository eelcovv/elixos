{pkgs, ...}: {
  # Ensure rootless Podman uses fuse-overlayfs and ignores chown errors at user level
  xdg.configFile."containers/storage.conf".text = ''
    [storage]
    driver = "overlay"

    [storage.options]
    mount_program = "${pkgs.fuse-overlayfs}/bin/fuse-overlayfs"
    ignore_chown_errors = "true"
  '';
}
