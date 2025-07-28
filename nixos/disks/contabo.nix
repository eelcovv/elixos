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
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
          };
        };
        root = {
          size = "70G";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
        swap = {
          size = "4G";
          content = {
            type = "swap";
          };
        };
        home = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/home";
            resizeable = true;
          };
        };
      };
    };
  };
}
