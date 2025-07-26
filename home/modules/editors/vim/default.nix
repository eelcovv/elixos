{
  config,
  pkgs,
  ...
}: {
  programs.vim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      vim-nix
    ];
  };

  home.file.".vimrc".source = ./vimrc;
}
