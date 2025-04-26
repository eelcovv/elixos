/**
 * This NixOS configuration defines a generic virtual machine setup.
 *
 * - **Imports**:
 *   - `../modules/common.nix`: Common configurations shared across systems.
 *   - `../modules/services/generic-vm.nix`: Service definitions specific to the generic VM.
 *   - `../hardware/generic-vm.nix`: Hardware configurations for the generic VM.
 *   - `../disks/generic-vm.nix`: Disk configurations for the generic VM.
 *   - `../users/eelco.nix`: User-specific configurations for "eelco".
 *
 * - **networking.hostName**: Sets the hostname of the machine to "generic-vm".
 * - **system.stateVersion**: Specifies the NixOS state version, set to "24.11".
 */
{ inputs, ... }:

{
  imports = [
    ../modules/common.nix
    ../modules/home-manager.nix
    ../modules/services/generic-vm.nix
    ../hardware/generic-vm.nix
    ../modules/disk-layouts/generic-vm.nix
    ../users/eelco.nix
    ../home/eelco.nix
  ];

  networking.hostName = "generic-vm";

}
