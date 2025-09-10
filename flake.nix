{
  description = "Eelco's NixOS Configuration";

  ##############################################################################
  # Inputs
  ##############################################################################
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    sops-nix.url = "github:Mic92/sops-nix";
    flake-utils.url = "github:numtide/flake-utils";
  };

  ##############################################################################
  # Outputs
  ##############################################################################
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

    # Users and hosts used to auto-generate system and HM configs
    allUsers = ["eelco" "por"];
    allHosts = ["singer" "tongfang" "ellie" "alloy" "contabo" "generic-vm"];

    enableHM = true;

    # Per-host top-level NixOS modules
    hostFiles = {
      tongfang = ./nixos/hosts/tongfang.nix;
      generic-vm = ./nixos/hosts/generic-vm.nix;
      test-vm = ./nixos/hosts/test-vm.nix;
      singer = ./nixos/hosts/singer.nix;
      ellie = ./nixos/hosts/ellie.nix;
      alloy = ./nixos/hosts/alloy.nix;
      contabo = ./nixos/hosts/contabo.nix;
    };

    # Which users live on which host
    hostUsersMap = {
      singer = ["eelco" "por"];
      tongfang = ["eelco"];
      ellie = ["eelco"];
      alloy = ["eelco"];
      contabo = ["eelco"];
      generic-vm = [];
      test-vm = [];
    };

    # Build one NixOS system for a given host
    mkHost = hostName: let
      users = hostUsersMap.${hostName} or [];
    in
      nixpkgs.lib.nixosSystem {
        # Make flake inputs available to NixOS modules
        specialArgs = {
          inherit inputs self;
          userModulesPath = ./home/users;
        };

        modules =
          [
            # Host base module
            hostFiles.${hostName}

            # Disko at system level (partitioning/formatting)
            disko.nixosModules.disko

            # sops-nix at system level (provides `sops.*` options and /run/secrets)
            sops-nix.nixosModules.sops

            # Home-Manager as a NixOS module (no HM sops here)
            home-manager.nixosModules.home-manager
          ]
          # Auto-import OS user modules based on hostUsersMap
          ++ builtins.map (u: ./nixos/users + "/${u}.nix") users
          # Home-Manager users only if present on this host
          ++ (
            if enableHM && users != []
            then [
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;

                # Define HM users as an attrset { eelco = { imports = [ ... ]; }; por = ...; }
                home-manager.users = nixpkgs.lib.genAttrs users (u: {
                  imports = [
                    # Pass flake inputs/userModulesPath to all HM submodules
                    {
                      _module.args = {
                        inherit inputs self;
                        userModulesPath = ./home/users;
                      };
                    }

                    # Your actual HM user configuration
                    (./home/users + "/${u}")
                  ];
                });
              }
            ]
            else []
          );
      };
  in {
    ############################################################################
    # DevShells for all default systems
    ############################################################################
    devShells = flake-utils.lib.eachDefaultSystem (
      sys: let
        pkgs = import nixpkgs {system = sys;};
      in {
        default = pkgs.mkShell {
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
            nodejs
          ];
          shellHook = ''
            echo "DevShell ready with pre-commit, sops, rage, qemu tools etc."
          '';
        };

        python = pkgs.mkShell {
          buildInputs = [
            pkgs.gcc
            pkgs.gfortran
            pkgs.cmake
            pkgs.pkg-config
            pkgs.python312
          ];
          shellHook = ''
            echo "🛠️  Python devShell (gcc, gfortran, cmake, pkg-config, python)"
            echo "👉  Use UV in this shell so that Scipy/Numpy Wheels find the Toolchain."
          '';
        };
      }
    );

    ############################################################################
    # NixOS hosts
    ############################################################################
    nixosConfigurations = builtins.mapAttrs (name: _: mkHost name) hostFiles;

    ############################################################################
    # Standalone Home-Manager profiles (outside NixOS)
    ############################################################################
    homeConfigurations = builtins.listToAttrs (
      builtins.concatMap
      (
        user:
          builtins.map
          (host: {
            name = "${user}@${host}";
            value = home-manager.lib.homeManagerConfiguration {
              pkgs = import nixpkgs {
                inherit system;
                config = {allowUnfree = true;};
              };
              modules = [
                # Make inputs available to HM modules
                {
                  _module.args = {
                    inherit inputs self;
                    userModulesPath = ./home/users;
                  };
                }

                # Your HM user configuration
                (./home/users + "/${user}")
              ];
            };
          })
          allHosts
      )
      allUsers
    );

    ############################################################################
    # Convenience: buildable system derivations per host (exclude test-vm)
    ############################################################################
    packages.${system} =
      builtins.mapAttrs
      (_: cfg: cfg.config.system.build.toplevel)
      (builtins.removeAttrs (builtins.mapAttrs (n: _: mkHost n) hostFiles) ["test-vm"]);

    ############################################################################
    # App entry for disko CLI
    ############################################################################
    apps.${system}.disko-install = {
      type = "app";
      program = "${disko.packages.${system}.disko}/bin/disko";
    };
  };
}
