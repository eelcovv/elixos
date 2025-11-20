{pkgs, ...}: {
  # Mount Windows C: (nvme0n1p2) on ~/Windows via ntfs3
  # Ensure the mount point exists before attempting to mount.
  systemd.tmpfiles.rules = [
    "d /home/eelco/Windows 0755 eelco users -"
  ];

  fileSystems."/home/eelco/Windows" = {
    device = "/dev/disk/by-uuid/82A41861A41859CD";
    fsType = "ntfs-3g";
    options = [
      "rw"
      "nofail"
      "x-systemd.automount" # load with first access
      "x-systemd.idle-timeout=600" # unmount after 10 min inactiviteit
      "uid=1000"
      "gid=100"
      "umask=022"
      "windows_names"
      "noatime"
      # eventueel: "ro"
    ];
  };
}
