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

    # OpenGL driver wrapper (NVIDIA/Intel/AMD) for GUI/VTK apps
    nixgl.url = "github:guibou/nixGL";
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
        # Expose flake inputs to NixOS modules
        specialArgs = {
          inherit inputs self;
          userModulesPath = ./home/users;
        };

        modules =
          [
            # Ensure hostPlatform is set for all hosts (required by newer NixOS)
            {nixpkgs.hostPlatform = nixpkgs.lib.mkDefault system;}

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
          ++ builtins.map (u: ./nixos/users + "/${u}.nix") users;
      };
  in {
    ############################################################################
    # DevShells for all default systems
    ############################################################################
    devShells = let
      # Limit to Linux systems (avoids Darwin breakages, e.g., OVMF on macOS)
      systems = ["x86_64-linux" "aarch64-linux"];

      # Build the shell set for one system
      mkShellSet = sys: let
        # Import pkgs for the target system
        pkgs = import nixpkgs {
          system = sys;
          config = {allowUnfree = true;};
        };

        # Import your centralized shells (parameterized by 'system')
        shells =
          (import ./nixos/modules/profiles/devshells/default.nix {
            inherit pkgs inputs;
            system = sys;
          }).devShells;

        # General-purpose dev shell; guard Linux-only packages
        general_default = pkgs.mkShell {
          packages = with pkgs;
            [
              pre-commit
              alejandra
              rage
              sops
              yq-go
              git
              openssh
              age
              just
              prettier
              nodejs
            ]
            ++ pkgs.lib.optionals pkgs.stdenv.isLinux [OVMF qemu];

          shellHook = ''
            echo "DevShell ready with pre-commit, sops, rage, qemu tools etc."
          '';
        };
      in
        shells
        // {
          general = general_default;
          default = shells.py_build; # convenience default
        };

      # System-first map: devShells.${system}.{py_build,py_light,py_vtk,default,general}
      bySystem = nixpkgs.lib.genAttrs systems mkShellSet;

      # Name-first map: devShells.{py_build,py_light,py_vtk,default,general}.${system}
      byName = flake-utils.lib.eachSystem systems mkShellSet;
    in
      byName // bySystem;

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
          (host: let
            pkgs = import nixpkgs {
              inherit system;
              config = {allowUnfree = true;};
            };
          in {
            name = "${user}@${host}";
            value = home-manager.lib.homeManagerConfiguration {
              inherit pkgs;

              modules = [
                # Expose inputs to HM modules
                {
                  _module.args = {
                    inherit inputs self;
                    userModulesPath = ./home/users;
                  };
                }

                # sops module (only for Home-Manager context)
                {
                  _module.args = {pkgs = pkgs;};
                  imports = [(import sops-nix {inherit pkgs;}).homeModules.sops];
                }

                # Actual HM user configuration
                ./home/users/${user}
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
