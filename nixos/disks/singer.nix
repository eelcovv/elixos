disk."main" = {
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
        content = {
          type = "luks";
          name = "crypt";
          settings.allowDiscards = true;
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
};

