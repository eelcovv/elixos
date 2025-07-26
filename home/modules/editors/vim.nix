{
  config,
  pkgs,
  ...
}: {
  programs.vim = {
    enable = true;
    extraConfig = ''
      syntax on
      set number
      set tabstop=4
      set shiftwidth=4
      set expandtab
    '';
    plugins = with pkgs.vimPlugins; [
      vim-nix
    ];
  };
}
