# This is a Nix flake configuration file for managing multiple NixOS configurations.
# 
# ## Description
# The flake defines a set of inputs and outputs to manage NixOS systems, packages, 
# and configurations. It uses various external repositories as inputs, such as 
# nixpkgs, nixos-hardware, home-manager, disko, and agenix.
# 
# ## Inputs
# - `nixpkgs`: Points to the NixOS unstable channel for the latest packages and modules.
# - `nixos-hardware`: Provides hardware-specific configurations for NixOS.
# - `home-manager`: A module for managing user environments and dotfiles.
# - `disko`: A tool for declarative disk partitioning and formatting.
# - `agenix`: A tool for managing age-encrypted secrets.
# 
# ## Outputs
# - `nixosConfigurations`: Defines multiple NixOS configurations for different systems:
#   - `tongfang`: Configuration for the "tongfang" host.
#   - `generic-vm`: Configuration for a generic virtual machine, including the disko module.
#   - `singer`: Configuration for the "singer" host.
#   - `contabo`: Configuration for the "contabo" host.
# 
# - `packages.x86_64-linux`: Provides the top-level system build outputs for each configuration:
#   - `tongfang`: Build output for the "tongfang" host.
#   - `generic-vm`: Build output for the generic virtual machine.
#   - `singer`: Build output for the "singer" host.
#   - `contabo`: Build output for the "contabo" host.
# 
# ## Notes
# - The `specialArgs` attribute is used to pass the flake inputs and self-reference to the NixOS configurations.
# - The `modules` attribute specifies the NixOS modules to include for each configuration.
# - The `disko.nixosModules.disko` module is included in the `generic-vm` configuration for disk management.
{
  description = "Eelco's NixOS Configuratie";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    home-manager.url = "github:nix-community/home-manager";
    disko.url = "github:nix-community/disko";
    agenix.url = "github:ryantm/agenix";
  };

  outputs = { self, nixpkgs, nixos-hardware, home-manager, disko, agenix, ... }@inputs: {

    # NixOS configuraties
    nixosConfigurations = {
      tongfang = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs self; };
        modules = [
          ./nixos/hosts/tongfang.nix
          # home-manager.nixosModules.home-manager
        ];
      };

      generic-vm = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs self; };
        modules = [
          ./nixos/hosts/generic-vm.nix
          disko.nixosModules.disko
          home-manager.nixosModules.home-manager
        ];
      };

      singer = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs self; };
        modules = [
          ./nixos/hosts/singer.nix
          disko.nixosModules.disko
          home-manager.nixosModules.home-manager
        ];
      };

      contabo = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs self; };
        modules = [
          ./nixos/hosts/contabo.nix
          disko.nixosModules.disko
          home-manager.nixosModules.home-manager
        ];
      };
    };

    # Packages (optional, if you need them for specific systems)
    # You could possibly replace this with:
    #Packages.x86_64-Linux = buildtins.Mapattrs (_: CFG: CFG.Config.System.build.toplevel) Self.nixos configuration;
    packages.x86_64-linux = rec {
      tongfang = self.nixosConfigurations.tongfang.config.system.build.toplevel;
      generic-vm = self.nixosConfigurations.generic-vm.config.system.build.toplevel;
      singer = self.nixosConfigurations.singer.config.system.build.toplevel;
      contabo = self.nixosConfigurations.contabo.config.system.build.toplevel;
    };
  };
}
