/**
 * This NixOS configuration defines a disk layout for a generic virtual machine using the `disko` module.
 *
 * - `disko.devices.disk.main`:
 *   - Represents the main disk device located at `/dev/vda`.
 *   - The disk is partitioned using the GPT partitioning scheme.
 *   - Contains two partitions:
 *     1. `boot`:
 *        - Size: 512 MB
 *        - Type: EFI System Partition (EF00)
 *        - Content:
 *          - Filesystem: vfat
 *          - Mountpoint: `/boot/efi`
 *     2. `root`:
 *        - Size: Remaining disk space (100%)
 *        - Name: `disk-main-root`
 *        - Content:
 *          - Filesystem: ext4
 *          - Mountpoint: `/`
 *          - Extra arguments: Sets the label of the filesystem to `disk-main-root`.
 *
 * - `fileSystems."/boot/efi".device`:
 *   - Ensures that the EFI partition is mounted at `/boot/efi` by explicitly setting the device to `/dev/vda1`.
 *   - Uses `lib.mkForce` to override any conflicting definitions.
 */
{ lib, ... }:

{ disko.devices = {
  disk.main = {
    type = "disk";
    device = "/dev/vda";

    content = {
      type = "gpt";
      partitions = {
        boot = {
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot/efi";
          };
        };
        root = {
          size = "100%";
          name = "disk-main-root"; 
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
            extraArgs = [ "-L" "disk-main-root" ];
          };

        };
      };
    };
  };
}; 

# Make sure the EFI partition is mounted
fileSystems."/boot/efi".device = lib.mkForce "/dev/vda1";

}
