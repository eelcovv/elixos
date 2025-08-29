{
  programs.direnv = {
    enable = true;
    nix-direnv = {
      enable = true;
      package = pkgs.nix-direnv; # jouw override mag ook
    };
    config.global.hide_env_diff = true;
  };

  home.file.".direnvrc".text = ''
    source "$(direnv stdlib)"

    # Helper om .venv (projectroot) te gebruiken via uv
    layout_my_venv() {
      local venv=".venv"
      if [ ! -f "$venv/bin/activate" ]; then
        uv venv
      fi
      source "$venv/bin/activate"
    }
  '';
}
