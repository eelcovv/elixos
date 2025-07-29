{config, ...}: {
  config.disko.devices = {
    disk = {
      my-disk = {
        device = "/dev/disk/by-id/nvme-WDC_PC_SN530_SDBPMPZ-256G-1101_210893456004";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              type = "EF00";
              size = "500M";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = ["defaults" "noatime" "fmask=0077" "dmask=0077"];
              };
            };

            luks-root = {
              size = "50G";
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

            luks-swap = {
              size = "6G";
              content = {
                type = "luks";
                name = "cryptswap";
                settings.allowDiscards = true;
                content = {
                  type = "swap";
                };
              };
            };

            luks-home = {
              size = "100%";
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
