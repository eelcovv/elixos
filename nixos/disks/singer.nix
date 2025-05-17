{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/sda";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            start = "1MiB";
            end = "513MiB";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          root = {
            start = "513MiB";
            end = "-8GiB"; # laat 8GiB over aan swap (of reserve)
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
            size = "8GiB";
            content = {
              type = "swap";
            };
          };
        };
      };
    };
  };
}

