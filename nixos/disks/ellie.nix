# Disk layout for host "ellie"
# - Uses stable references:
#   * LUKS unlock in initrd via /dev/disk/by-partlabel/ellie-...
#   * Filesystems have human-readable labels (ELLIE-...)
#
# WARNING: Using disko with --mode zap_create_mount WILL WIPE the drive.
{lib, ...}: {
  disko.devices = {
    disk = {
      "nvme0n1" = {
        type = "disk";
        # Verify this with: ls -l /dev/disk/by-id | grep -i UMIS
        device = "/dev/disk/by-id/nvme-UMIS_RPJTJ256MEE1OWX_SS1B60641Z1CD13A21BT";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              # EFI System Partition (unencrypted)
              name = "ellie-boot"; # → /dev/disk/by-partlabel/ellie-boot
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                label = "ELLIE-ESP"; # → /dev/disk/by-label/ELLIE-ESP
                mountpoint = "/boot";
                mountOptions = ["umask=0077"];
              };
            };

            root = {
              # Encrypted root (100 GiB)
              name = "ellie-root"; # → /dev/disk/by-partlabel/ellie-root
              size = "100G";
              content = {
                type = "luks";
                name = "cryptroot"; # → /dev/mapper/cryptroot
                settings.allowDiscards = true;
                content = {
                  type = "filesystem";
                  format = "ext4";
                  label = "ELLIE-ROOT"; # → /dev/disk/by-label/ELLIE-ROOT
                  mountpoint = "/";
                };
              };
            };

            swap = {
              # Encrypted swap (8 GiB)
              name = "ellie-swap"; # → /dev/disk/by-partlabel/ellie-swap
              size = "8G";
              content = {
                type = "luks";
                name = "cryptswap"; # → /dev/mapper/cryptswap
                settings.allowDiscards = true;
                content = {
                  type = "swap";
                  # This will set the systemd resume device automatically.
                  resumeDevice = true;
                  # Optional: you can label swap inside the mapper with mkswap later if desired.
                };
              };
            };

            home = {
              # Encrypted home (rest of disk)
              name = "ellie-home"; # → /dev/disk/by-partlabel/ellie-home
              size = "100%";
              content = {
                type = "luks";
                name = "crypthome"; # → /dev/mapper/crypthome
                settings.allowDiscards = true;
                content = {
                  type = "filesystem";
                  format = "ext4";
                  label = "ELLIE-HOME"; # → /dev/disk/by-label/ELLIE-HOME
                  mountpoint = "/home";
                };
              };
            };
          };
        };
      };
    };
  };
}
