{lib, ...}: {
  disko.devices = {
    disk = {
      "samsung-linux" = {
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
                mountpoint = "/boot"; # systemd-boot expects /boot
                mountOptions = ["umask=0077"];
              };
            };

            root = {
              size = "200G";
              content = {
                type = "luks";
                name = "cryptroot";
                settings.allowDiscards = true;
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
                settings = {
                  allowDiscards = true;
                  keyFile = "/tmp/installer/cryptswap.key"; # <- moved here
                };
                askPassword = false;
                initrdUnlock = true;
                content = {
                  type = "swap";
                  resumeDevice = true;
                };
              };
            };

            home = {
              size = "100%";
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

      # NOTE: Do NOT declare the Windows disk at all; Disko will ignore it.
    };
  };
}
