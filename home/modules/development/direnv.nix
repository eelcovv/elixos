{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.direnv = {
    enable = true;
    nix-direnv = {
      enable = true;
    };
    config.global.hide_env_diff = true;
  };

  home.file.".direnvrc".text = ''
    # Load the DirenV STDLIB (Correct): Evaluate the content
    eval "$(direnv stdlib)"

    # Helper to make/activate .venv automatically via uv
    layout_my_venv() {
      local venv=".venv"
      if [ ! -f "$venv/bin/activate" ]; then
        uv venv
      fi
      # shellcheck disable=SC1091
      source "$venv/bin/activate"
    }
  '';
}
