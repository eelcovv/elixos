
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
    nixosConfigurations = {
      tongfang = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./nixos/hosts/tongfang.nix
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
  };
}
