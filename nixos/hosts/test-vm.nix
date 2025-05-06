{ config, pkgs, ... }:

{
  networking.hostName = "test-vm";
  services.openssh.enable = true;
  programs.zsh.enable = true;

  environment.etc."build-marker".text = "force rebuild";

  users.users.root = {
    initialPassword = "bla";
  };
  users.users.eelco = {
    isNormalUser = true;
    createHome = true;
    home = "/home/eelco";
    initialPassword = "bla";
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC3+DBjLHGlQinS0+qeC5JgFakaPFc+b+btlZABO7ZX6 eelco@tongfang"
    ];
  };

  system.stateVersion = "24.11";
}

