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

  # Set the target hostname
  networking.hostName = "generic-vm";

  # Choose what desktop you want to make available
  desktop.enableGnome = true;
  desktop.enableKde = false;
  desktop.enableHyperland = false;

  # Definine host-specifi sshUsers
  configuredUsers = [ "eelco" ];
  sshUsers = [ "eelco" ];


  imports = [
    ../modules/common.nix
    ../modules/profiles/desktop.nix
    ../modules/home-manager.nix
    ../users/eelco.nix
    ../modules/secrets/default.nix
    ../modules/secrets/generic-vm-eelco.nix
    ../modules/services/ssh-client-keys.nix
    ../hardware/generic-vm.nix
    ../modules/disk-layouts/generic-vm.nix
  ];
}
