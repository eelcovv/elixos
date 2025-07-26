{
  config,
  pkgs,
  ...
}: {
  programs.vim = {
    plugins = with pkgs.vimPlugins; [
      vim-nix
    ];
  };

  home.file.".vimrc".source = ./vimrc;
}
