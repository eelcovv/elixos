{ pkgs, ... }: {
  home.packages = with pkgs; [
    neovim
    git
    htop
    wget
    curl
    tree
  ];
}
