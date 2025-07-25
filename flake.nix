# This is a Nix flake configuration file for managing multiple NixOS configurations.
#
# ## Description
# The flake defines a set of inputs and outputs to manage NixOS systems, packages,
# and configurations. It uses various external repositories as inputs, such as
# nixpkgs, nixos-hardware, home-manager, disko, and sops.
#
# ## Inputs
# - `nixpkgs`: Points to the NixOS unstable channel for the latest packages and modules.
# - `nixos-hardware`: Provides hardware-specific configurations for NixOS.
# - `home-manager`: A module for managing user environments and dotfiles.
# - `disko`: A tool for declarative disk partitioning and formatting.
# - `sops-nix`: A tool for managing age-encrypted secrets.
#
# ## Outputs
# - `nixosConfigurations`: Defines multiple NixOS configurations for different systems:
#   - `tongfang`: Configuration for the "tongfang" host.
#   - `generic-vm`: Configuration for a generic virtual machine, including the disko module.
#   - `singer`: Configuration for the "singer" host.
#   - `ellie`: Configuration for the "ellie" host.
#   - `alloy`: Configuration for the "alloy" host.
#   - `contabo`: Configuration for the "contabo" host.
#
# - `packages.x86_64-linux`: Provides the top-level system build outputs for each configuration:
#   - `tongfang`: Build output for the "tongfang" host.
#   - `generic-vm`: Build output for the generic virtual machine.
#   - `alloy`: Build output for the "alloy" host.
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
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko";
    sops-nix.url = "github:Mic92/sops-nix";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    nixos-hardware,
    home-manager,
    disko,
    sops-nix,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
        };
      in {
        # Development shell for tools like pre-commit, alejandra, rage, etc.
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            pre-commit
            alejandra
            rage
            sops
            yq-go
            OVMF
            qemu
            git
            openssh
            age
            just
            prettier
            pre-commit
            nodejs # Needed for Prettier Cli
          ];

          shellHook = ''
            echo "DevShell ready with pre-commit, sops, rage, qemu tools etc."
          '';
        };
      }
    )
    // {
      # NixOS system configurations
      nixosConfigurations = {
        tongfang = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs self;
            userModulesPath = ./home/users;
          };
          modules = [
            ./nixos/hosts/tongfang.nix
            disko.nixosModules.disko
            home-manager.nixosModules.home-manager
            sops-nix.nixosModules.sops
          ];
        };

        generic-vm = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs self;
            userModulesPath = ./home/users;
          };
          modules = [
            ./nixos/hosts/generic-vm.nix
            disko.nixosModules.disko
            home-manager.nixosModules.home-manager
            sops-nix.nixosModules.sops
          ];
        };

        test-vm = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs self;
            userModulesPath = ./home/users;
          };
          modules = [
            ./nixos/hosts/test-vm.nix
          ];
        };

        singer = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs self;
            userModulesPath = ./home/users;
          };
          modules = [
            ./nixos/hosts/singer.nix
            disko.nixosModules.disko
            home-manager.nixosModules.home-manager
            sops-nix.nixosModules.sops
          ];
        };
        ellie = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs self;
            userModulesPath = ./home/users;
          };
          modules = [
            ./nixos/hosts/ellie.nix
            disko.nixosModules.disko
            home-manager.nixosModules.home-manager
            sops-nix.nixosModules.sops
          ];
        };
        alloy = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs self;
            userModulesPath = ./home/users;
          };
          modules = [
            ./nixos/hosts/alloy.nix
            disko.nixosModules.disko
            home-manager.nixosModules.home-manager
            sops-nix.nixosModules.sops
          ];
        };

        # contabo = nixpkgs.lib.nixosSystem {
        #   system = "x86_64-linux";
        #   specialArgs = {
        #     inherit inputs self;
        #     userModulesPath = ./home/users;
        #   };
        #   modules = [
        #     ./nixos/hosts/contabo.nix
        #     disko.nixosModules.disko
        #     home-manager.nixosModules.home-manager
        #     sops-nix.nixosModules.sops
        #   ];
        # };
      };

      # Toplevel system packages per host
      packages.x86_64-linux = rec {
        tongfang = self.nixosConfigurations.tongfang.config.system.build.toplevel;
        generic-vm = self.nixosConfigurations.generic-vm.config.system.build.toplevel;
        test-vm = self.nixosConfigurations.test-vm.config.system.build.toplevel;
        singer = self.nixosConfigurations.singer.config.system.build.toplevel;
        ellie = self.nixosConfigurations.ellie.config.system.build.toplevel;
        alloy = self.nixosConfigurations.alloy.config.system.build.toplevel;
        # contabo = self.nixosConfigurations.contabo.config.system.build.toplevel;
      };
    };
}
