{lib, ...}: {
  # Disk layout voor Tongfang-laptop.
  disko.devices = {
    disk = {
      # with multiple drives, it is not safe to use
      # the device by number, like nvme0n1, if you have
      # windows on nvme1n1, because the order is not
      # guarenteed. Therefore, use the real device name to
      # distingish the drives, like.
      # ls -l /dev/disk/by-id/ | grep SAMSUNG ^
      # do not use the backslash
      "nvme0n1" = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-SAMSUNG_MZVL21T0HCLR-00B00_S676NL0W804929";

        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot/efi";
                mountOptions = ["umask=0077"];
              };
            };

            swap = {
              size = "96G";
              content = {
                type = "luks";
                name = "cryptswap";
                settings.allowDiscards = true;
                content = {
                  type = "swap";
                  resumeDevice = true;
                };
              };
            };

            root = {
              size = "200G";
              content = {
                type = "luks";
                name = "cryptroot";
                settings.allowDiscards = true;
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                };
              };
            };

            home = {
              size = "100%"; # Gebruik de rest van de schijf
              content = {
                type = "luks";
                name = "crypthome";
                settings.allowDiscards = true;
                content = {
                  type = "filesystem";
                  format = "ext4";
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
