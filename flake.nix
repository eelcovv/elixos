{
  description = "Eelco's NixOS Configuration";

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
    disko,
    home-manager,
    sops-nix,
    flake-utils,
    ...
  }: let
    system = "x86_64-linux";

    allUsers = ["eelco" "por"];
    allHosts = ["singer" "tongfang" "ellie" "alloy" "contabo" "generic-vm"];

    # Enable Home Manager for all hosts, or only for specific ones.
    enableHM = true;

    hostFiles = {
      tongfang = ./nixos/hosts/tongfang.nix;
      generic-vm = ./nixos/hosts/generic-vm.nix;
      test-vm = ./nixos/hosts/test-vm.nix;
      singer = ./nixos/hosts/singer.nix;
      ellie = ./nixos/hosts/ellie.nix;
      alloy = ./nixos/hosts/alloy.nix;
      contabo = ./nixos/hosts/contabo.nix;
    };

    hostUserMap = {
      singer = "eelco";
      tongfang = "eelco";
      ellie = "eelco";
      alloy = "eelco";
      contabo = "eelco";
      # generic-vm/test-vm geen vaste user → laat weg of voeg toe indien gewenst
    };

    mkHost = hostName: let
      user = hostUserMap.${hostName} or null;
    in
      nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs self;
          userModulesPath = ./home/users;
        };
        modules =
          [
            hostFiles.${hostName}
            disko.nixosModules.disko
            home-manager.nixosModules.home-manager
            sops-nix.nixosModules.sops
          ]
          ++ (
            if enableHM && user != null
            then [
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;

                # ⬇️ Belangrijk: importeer de directory (default.nix) i.p.v. ${user}.nix
                home-manager.users.${user} = import ./home/users/${user};
              }
            ]
            else []
          );
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

    # NixOS hosts
    nixosConfigurations = builtins.mapAttrs (name: _: mkHost name) hostFiles;

    # Losse Home Manager configs per user@host
    homeConfigurations = builtins.listToAttrs (
      builtins.concatMap (
        user:
          builtins.map (
            host: {
              name = "${user}@${host}";
              value = home-manager.lib.homeManagerConfiguration {
                pkgs = import nixpkgs {
                  inherit system;
                  config = {allowUnfree = true;};
                };
                modules = [
                  ./home/users/${user}
                ];
                extraSpecialArgs = {
                  inherit inputs self;
                  userModulesPath = ./home/users;
                };
              };
            }
          )
          allHosts
      )
      allUsers
    );

    # Handige outputs
    packages.x86_64-linux = builtins.mapAttrs (
      _name: cfg: cfg.config.system.build.toplevel
    ) (builtins.removeAttrs (builtins.mapAttrs (name: _: mkHost name) hostFiles) ["test-vm"]);

    apps.x86_64-linux.disko-install = {
      type = "app";
      program = "${disko.packages.x86_64-linux.disko}/bin/disko";
    };
  };
}
