{lib, ...}: {
  # Disk layout voor Tongfang-laptop (veilig: raakt alleen de Linux-disk).
  disko.devices = {
    disk = {
      # with multiple drives, it is not safe to use
      # the device by number, like nvme0n1, if you have
      # windows on nvme1n1, because the order is not
      # guarenteed. Therefore, use the real device name to
      # distingish the drives, like.
      # ls -l /dev/disk/by-id/ | grep SAMSUNG ^
      # do not use the backslash
      # also, make use to include all the details, also the serial number
      "nvme0n1" = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-SAMSUNG_MZVL21T0HCLR-00B00_S676NL0W803075";

        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                # systemd-boot verwacht ESP op /boot
                mountpoint = "/boot";
                mountOptions = ["umask=0077"];
              };
            };

            root = {
              size = "200G";
              content = {
                type = "luks";
                name = "cryptroot";
                settings.allowDiscards = true;
                # non-interactief + initrd unlock
                askPassword = false;
                passwordFile = "/tmp/installer/cryptroot.pass";
                initrdUnlock = true;
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                };
              };
            };

            swap = {
              size = "96G";
              content = {
                type = "luks";
                name = "cryptswap";
                settings.allowDiscards = true;
                askPassword = false;
                keyFile = "/tmp/installer/cryptswap.key";
                initrdUnlock = false;
                content = {
                  type = "swap";
                  resumeDevice = true;
                };
              };
            };

            home = {
              size = "100%"; # rest van de schijf
              content = {
                type = "luks";
                name = "crypthome";
                settings.allowDiscards = true;
                askPassword = false;
                passwordFile = "/tmp/installer/crypthome.pass";
                initrdUnlock = false;
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

      # Windows-disk: expliciet benoemen, maar GEEN 'content' => disko blijft er vanaf.
      "samsung-windows" = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-SAMSUNG_MZVL21T0HCLR-00B00_S676NL0W804929";
      };
    };
  };
}
