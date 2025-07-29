{
  description = "Minimal tools for bootstrap";

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";

  outputs = {nixpkgs, ...}: {
    packages.x86_64-linux.default = with nixpkgs.legacyPackages.x86_64-linux;
      buildEnv {
        name = "bootstrap-tools";
        paths = [git just];
      };
  };
}
