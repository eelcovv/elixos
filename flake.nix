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
  outputs = inputs@{ self, nixpkgs, disko, home-manager, sops-nix, flake-utils, ... }:
  let
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
        specialArgs = { inherit inputs self; userModulesPath = ./home/users; };
        modules = [
          { nixpkgs.hostPlatform = nixpkgs.lib.mkDefault system; } # Ensure hostPlatform
          hostFiles.${hostName}                                    # Host base module
          disko.nixosModules.disko                                  # Disko module
          sops-nix.nixosModules.sops                                # sops-nix at system level
          home-manager.nixosModules.home-manager                   # HM module
        ]
        ++ builtins.map (u: ./nixos/users + "/${u}.nix") users;      # Auto-import OS user modules
      };
  in
  {
    ############################################################################
    # DevShells for all default systems
    ############################################################################
    devShells = let
      systems = ["x86_64-linux" "aarch64-linux"];
      mkShellSet = sys: let
        pkgs = import nixpkgs { system = sys; config = { allowUnfree = true; }; };
        shells = (import ./nixos/modules/profiles/devshells/default.nix { inherit pkgs inputs; system = sys; }).devShells;
        general_default = pkgs.mkShell {
          packages = with pkgs; [
            pre-commit alejandra rage sops yq-go git openssh age just prettier nodejs
          ] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [OVMF qemu];
          shellHook = ''
            echo "DevShell ready with pre-commit, sops, rage, qemu tools etc."
          '';
        };
      in shells // { general = general_default; default = shells.py_build; };
      bySystem = nixpkgs.lib.genAttrs systems mkShellSet;
      byName = flake-utils.lib.eachSystem systems mkShellSet;
    in byName // bySystem;

    ############################################################################
    # NixOS hosts
    ############################################################################
    nixosConfigurations = builtins.mapAttrs (name: _: mkHost name) hostFiles;

    ############################################################################
    # Standalone Home-Manager profiles (outside NixOS)
    ############################################################################
    homeConfigurations = builtins.listToAttrs (
      builtins.concatMap (user:
        builtins.map (host:
          let
            pkgs = import nixpkgs { inherit system; config = { allowUnfree = true; }; };
          in {
            name = "${user}@${host}";
            value = home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              modules = [
                { _module.args = { inherit inputs self; userModulesPath = ./home/users; }; }
                {}
                ./home/users/${user}
              ];
            };
          }
        ) allHosts
      ) allUsers
    );

    ############################################################################
    # Convenience: buildable system derivations per host (exclude test-vm)
    ############################################################################
    packages.${system} = builtins.mapAttrs (_: cfg: cfg.config.system.build.toplevel)
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

