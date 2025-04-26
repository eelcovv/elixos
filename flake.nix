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
        ];
      };

      generic-vm = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs self; };
        modules = [
          ./nixos/hosts/generic-vm.nix
          disko.nixosModules.disko
        ];
      };

      singer = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs self; };
        modules = [
          ./nixos/hosts/singer.nix
        ];
      };

      contabo = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs self; };
        modules = [
          ./nixos/hosts/contabo.nix
        ];
      };
    };

    # Packages (optioneel, als je ze nodig hebt voor specifieke systemen)
    # dit zou je eventueel kunnen vervangen door:
    #packages.x86_64-linux = builtins.mapAttrs (_: cfg: cfg.config.system.build.toplevel) self.nixosConfigurations;
    packages.x86_64-linux = rec {
      tongfang = self.nixosConfigurations.tongfang.config.system.build.toplevel;
      generic-vm = self.nixosConfigurations.generic-vm.config.system.build.toplevel;
      singer = self.nixosConfigurations.singer.config.system.build.toplevel;
      contabo = self.nixosConfigurations.contabo.config.system.build.toplevel;
    };
  };
}
