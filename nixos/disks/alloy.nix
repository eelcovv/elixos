{ lib, ... }:

{
  disko.devices = {
    disk = {
      "nvme0n1" = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_1TB_S5H9NS0NB56449Z";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = ["umask=0077"];
              };
            };

            swap = {
              size = "34G";
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

