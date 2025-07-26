{pkgs, ...}: {
  home.packages = with pkgs; [
    git
    htop
    wget
    curl
    tree
    alejandra
  ];
}
