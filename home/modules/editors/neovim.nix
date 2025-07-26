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
    extraConfig = ''
      set number
      set relativenumber
      set tabstop=2
      set shiftwidth=2
      set expandtab
      syntax on
    '';
    plugins = with pkgs.vimPlugins; [
      vim-nix
      telescope-nvim
      plenary-nvim
    ];
  };
}
