{
  disko.devices.disk.sda = {
    type = "disk";
    device = "/dev/sda";
    content = {
      type = "gpt";
      partitions = {
        boot = {
          size = "512M";
          type = "EF00";
          format = "vfat";
          mountpoint = "/boot";
        };
        root = {
          size = "70G";
          format = "ext4";
          mountpoint = "/";
        };
        swap = {
          size = "4G";
          format = "swap";
          swap = true;
        };
        home = {
          size = "100%";
          format = "ext4";
          mountpoint = "/home";
          resizeable = true;
        };
      };
    };
  };
}
