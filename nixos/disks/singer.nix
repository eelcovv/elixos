{ config, lib, ... }:

{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/sda";  # You might need to adjust this after checking `lsblk`
      content = {
        type = "gpt";
        partitions = [
          {
            name = "ESP";
            start = "1MiB";
            end = "513MiB";
            bootable = true;
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          }
          {
            name = "root";
            start = "513MiB";
            end = "100%";
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
          }
        ];
      };
    };
    swapDevices = [
      {
        device = "/swapfile";
        size = "8G";
      }
    ];
  };
}
