{
  home-manager.users.eelco = {
    home.stateVersion = "24.11";

    imports = [
      (import ./modules/git.nix {
        userName = "Eelco van Vliet";
        userEmail = "eelcovv@gmail.com";
      })
      ./modules/zsh.nix
      ./modules/common-packages.nix
    ];
  };
}