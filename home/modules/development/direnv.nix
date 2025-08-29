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
      package =
        lib.mkIf (config.nix.package != null)
        (pkgs.nix-direnv.override {nix = config.nix.package;});
    };
    config.global.hide_env_diff = true;
  };

  home.file.".direnvrc".text = ''
    source_url "https://raw.githubusercontent.com/direnv/direnv/master/stdlib.sh"

    # (optioneel) eigen fallback helper om .venv te gebruiken met uv:
    layout_my_venv() {
      local venv=".venv"
      if [ ! -f "$venv/bin/activate" ]; then
        uv venv
      fi
      source "$venv/bin/activate"
    }
  '';
}
