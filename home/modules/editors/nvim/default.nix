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
      vim-nix # Nix syntax
      (nvim-treesitter.withPlugins (p: with p; [python latex nix lua]))
      gruvbox
      catppuccin-nvim
      tokyonight-nvim
      nord-vim
      telescope-nvim
      plenary-nvim
      nvim-treesitter # moderne syntax highlighting
      vimtex # LaTeX editing
      nvim-lspconfig # LSP client
      nvim-cmp # autocompletion framework
      cmp-nvim-lsp # LSP source for nvim-cmp
      cmp-buffer # buffer completion
      cmp-path # file path completion
      cmp-spell # spelling
      lspkind-nvim # nice icons in autocompletion
      lualine-nvim # statusline
    ];
  };

  xdg.configFile."nvim/init.lua".source = ./init.lua;
}
