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
        specialArgs = { inherit inputs; };
        modules = [
          ./nixos/hosts/tongfang.nix
        ];
      };

      tongfang-vm = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./nixos/hosts/tongfang-vm.nix
          disko.nixosModules.disko
        ];
      };

      singer = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./nixos/hosts/singer.nix
        ];
      };

      contabo = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./nixos/hosts/contabo.nix
        ];
      };
    };

    # Packages (optioneel, als je ze nodig hebt voor specifieke systemen)
    packages.x86_64-linux = rec {
      tongfang = self.nixosConfigurations.tongfang.config.system.build.toplevel;
      tongfang-vm = self.nixosConfigurations.tongfang-vm.config.system.build.toplevel;
      singer = self.nixosConfigurations.singer.config.system.build.toplevel;
      contabo = self.nixosConfigurations.contabo.config.system.build.toplevel;
    };
  };
}
