{
  description = "Minimal test system";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }: {
    nixosConfigurations.test-vm = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        {
          networking.hostName = "test-vm";
          services.openssh.enable = true;
          users.users.eelco = {
            isNormalUser = true;
            createHome = true;
            home = "/home/eelco";
            shell = nixpkgs.legacyPackages.x86_64-linux.zsh;
            openssh.authorizedKeys.keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC3+DBjLHGlQinS0+qeC5JgFakaPFc+b+btlZABO7ZX6 eelco@tongfang"
            ];
          };
          system.stateVersion = "24.11";
        }
      ];
    };
  };
}