# run this with: sudo nix run --extra-experimental-features 'nix-command flakes' github:nix-community/disko -- --flake .#singer --mode zap_create_mount
{
  disko.devices = {
    disk = {
      my-disk = {
        # only use device references with a number like this if you dont have other hardrives!
        # See comment with tongfang.nix
        device = "/dev/nvme0n1";
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
                mountpoint = "/boot/efi";
                mountOptions = ["umask=0077"];
              };
            };
            luks = {
              size = "100%";
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
          };
        };
      };
    };
  };
}
