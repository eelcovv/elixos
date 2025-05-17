
{ config, lib, ... }:

{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/sda";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          start = "1MiB";
          end = "513MiB";
          label = "boot";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
          };
        };

        root = {
          start = "513MiB";
          end = "100% - 8GiB";
          label = "root";
          content = {
            type = "luks";
            name = "crypted";
            settings.allowDiscards = true;
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };

        swap = {
          start = "100% - 8GiB";
          end = "100%";
          label = "swap";
          content = {
            type = "swap";
          };
        };
      };
    };
  };
}
