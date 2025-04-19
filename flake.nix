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

    packages.x86_64-linux.tongfang = self.nixosConfigurations.tongfang.config.system.build.toplevel;
    nixosConfigurations = {
      tongfang = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./nixos/configuration.nix
          ./nixos/hosts/tongfang.nix
        ];
      };

      packages.x86_64-linux.singer = self.nixosConfigurations.singer.config.system.build.toplevel;
      singer = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./nixos/configuration.nix
          ./nixos/hosts/singer.nix
        ];
      };

      packages.x86_64-linux.contabo = self.nixosConfigurations.contabo.config.system.build.toplevel;
      contabo = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./nixos/configuration.nix
          ./nixos/hosts/contabo.nix
        ];
      };
    };
  };
}
