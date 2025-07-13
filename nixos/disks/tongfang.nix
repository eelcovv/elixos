# run this with: sudo nix run --extra-experimental-features 'nix-command flakes' github:nix-community/disko -- --flake .#singer --mode zap_create_mount
{
  disko.devices = {
    disk = {
      nvme0n1 = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot/efi";
                mountOptions = [ "umask=0077" ];
              };
            };

            swap = {
              size = "96G";
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
              size = "100%"; # rest van de schijf
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
