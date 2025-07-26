{
  config,
  pkgs,
  ...
}: {
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    withPython3 = true;
    plugins = with pkgs.vimPlugins; [
      vim-nix
      telescope-nvim
      plenary-nvim
    ];
  };
  home.file.".config/nvim/init.vim".source = ./init.vim;
}
