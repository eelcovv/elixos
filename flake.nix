{
  description = "Eelco's NixOS Configuration";

  # Inputs: Define external sources for modules, tools and package sets
  inputs = {
    # Official NixOS package set (unstable channel)
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Hardware-specific modules for various devices
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    # Home Manager for managing user environments and dotfiles
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Declarative disk partitioning and formatting
    disko.url = "github:nix-community/disko";

    # Encrypted secret management using age/sops
    sops-nix.url = "github:Mic92/sops-nix";

    # Utility flake to build per-system outputs (devShells, packages, etc.)
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    disko,
    home-manager,
    sops-nix,
    flake-utils,
    ...
  }: let
    # Reusable function to define a nixosSystem configuration
    mkHost = hostFile:
      nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs self;
          userModulesPath = ./home/users; # Passed to Home Manager modules
        };
        modules = [
          hostFile
          disko.nixosModules.disko
          home-manager.nixosModules.home-manager
          sops-nix.nixosModules.sops
        ];
      };
    homeUsers = {
      "eelco@singer" = ./home/users/eelco.nix;
      "eelco@tongfang" = ./home/users/eelco.nix;
      "eelco@ellie" = ./home/users/eelco.nix;
      "eelco@alloy" = ./home/users/eelco.nix;
      "eelco@contabo" = ./home/users/eelco.nix;
    };

    # Map of host names to their NixOS configuration files
    hostFiles = {
      tongfang = ./nixos/hosts/tongfang.nix;
      generic-vm = ./nixos/hosts/generic-vm.nix;
      test-vm = ./nixos/hosts/test-vm.nix;
      singer = ./nixos/hosts/singer.nix;
      ellie = ./nixos/hosts/ellie.nix;
      alloy = ./nixos/hosts/alloy.nix;
      contabo = ./nixos/hosts/contabo.nix;
      # contabo = ./nixos/hosts/contabo.nix;  # Uncomment if needed
    };
  in {
    # Outputs contain two parts:
    # - devShells: Development environments per system
    # - nixosConfigurations: System definitions for each host
    devShells = flake-utils.lib.eachDefaultSystem (system: {
      devShells.default = (import nixpkgs {inherit system;}).mkShell {
        packages = with (import nixpkgs {inherit system;}); [
          pre-commit # Git hook runner
          alejandra # Nix code formatter
          rage # Age key management
          sops # Secrets management
          yq-go # YAML CLI processor
          OVMF # UEFI firmware for VMs
          qemu # Virtual machine tool
          git
          openssh
          age # Age encryption tool
          just # Task runner
          prettier # JS/CSS/JSON formatter
          nodejs # Required by prettier
        ];

        shellHook = ''
          echo "DevShell ready with pre-commit, sops, rage, qemu tools etc."
        '';
      };
    });

    # System configuration per host
    nixosConfigurations = builtins.mapAttrs (_name: mkHost) hostFiles;

    homeConfigurations =
      builtins.mapAttrs (
        fullKey: moduleFile:
          home-manager.lib.homeManagerConfiguration {
            pkgs = import nixpkgs {
              system = "x86_64-linux";
              config.allowUnfree = true;
            };
            modules = [moduleFile];
            extraSpecialArgs = {
              inherit inputs self;
            };
          }
      )
      homeUsers;

    # Package outputs (e.g., used by nix build .#tongfang)
    packages.x86_64-linux = builtins.mapAttrs (
      _name: cfg:
        cfg.config.system.build.toplevel
    ) (builtins.removeAttrs (builtins.mapAttrs (_: mkHost) hostFiles) ["test-vm"]);

    # Disko runner app
    apps.x86_64-linux.disko-install = {
      type = "app";
      program = "${disko.packages.x86_64-linux.disko}/bin/disko";
    };
  };
}
