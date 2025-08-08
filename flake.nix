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
    system = "x86_64-linux";

    allUsers = ["eelco", "por"];
    allHosts = ["singer" "tongfang" "ellie" "alloy" "contabo"];

    hostFiles = {
      tongfang = ./nixos/hosts/tongfang.nix;
      generic-vm = ./nixos/hosts/generic-vm.nix;
      test-vm = ./nixos/hosts/test-vm.nix;
      singer = ./nixos/hosts/singer.nix;
      ellie = ./nixos/hosts/ellie.nix;
      alloy = ./nixos/hosts/alloy.nix;
      contabo = ./nixos/hosts/contabo.nix;
    };

    mkHost = hostFile:
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs self;
          userModulesPath = ./home/users;
        };
        modules = [
          hostFile
          disko.nixosModules.disko
          home-manager.nixosModules.home-manager
          sops-nix.nixosModules.sops
        ];
      };
  in {
    devShells = flake-utils.lib.eachDefaultSystem (system: {
      devShells.default = (import nixpkgs {inherit system;}).mkShell {
        packages = with (import nixpkgs {inherit system;}); [
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
          nodejs
        ];
        shellHook = ''
          echo "DevShell ready with pre-commit, sops, rage, qemu tools etc."
        '';
      };
    });

    nixosConfigurations = builtins.mapAttrs (_: mkHost) hostFiles;

    homeConfigurations = builtins.listToAttrs (
      builtins.concatMap (
        user:
          builtins.map (host: {
            name = "${user}@${host}";
            value = home-manager.lib.homeManagerConfiguration {
              inherit system;
              pkgs = nixpkgs.legacyPackages.${system};
              modules = [
                ./home/users/${user}.nix
              ];
              extraSpecialArgs = {
                inherit inputs self;
                userModulesPath = ./home/users;
              };
            };
          })
          allHosts
      )
      allUsers
    );

    packages.x86_64-linux = builtins.mapAttrs (
      _name: cfg: cfg.config.system.build.toplevel
    ) (builtins.removeAttrs (builtins.mapAttrs (_: mkHost) hostFiles) ["test-vm"]);

    apps.x86_64-linux.disko-install = {
      type = "app";
      program = "${disko.packages.x86_64-linux.disko}/bin/disko";
    };
  };
}
