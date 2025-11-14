{pkgs, ...}: {
  # Mount Windows C: (nvme0n1p2) on ~/Windows via ntfs3
  # Ensure the mount point exists before attempting to mount.
  system.activationScripts.makeWindowsMountPoint = ''
    mkdir -p /home/eelco/Windows
    chown eelco:users /home/eelco/Windows
  '';

  fileSystems."/home/eelco/Windows" = {
    device = "/dev/disk/by-uuid/82A41861A41859CD";
    fsType = "ntfs3";
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
