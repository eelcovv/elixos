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
            size = "100%"; # Gebruik de volledige rest van de schijf
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
        };
      };
    };

    # Swapfile declaratief (via systemd)
    swapDevices = [
      {
        device = "/swapfile";
        size = "8G";
      }
    ];
  };
}
