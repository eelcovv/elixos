{
  config,
  pkgs,
  lib,
  ...
}: let
  wpDir = "${config.xdg.configHome}/wallpapers";
  wpRepoUrl = "https://github.com/mylinuxforwork/wallpaper";
  wpRepoBranch = "main";

  fetchScript = pkgs.writeShellScript "fetch-wallpapers.sh" ''
    set -euo pipefail
    echo "📥 Downloading wallpapers from ${wpRepoUrl} ..."
    export GIT_TERMINAL_PROMPT=0
    export GIT_ASKPASS=true

    if [ -d "${wpDir}/.git" ]; then
      ${pkgs.git}/bin/git -C "${wpDir}" remote set-url origin "${wpRepoUrl}" || true
      ${pkgs.git}/bin/git -C "${wpDir}" fetch --depth=1 origin "${wpRepoBranch}"
      ${pkgs.git}/bin/git -C "${wpDir}" reset --hard FETCH_HEAD
      ${pkgs.git}/bin/git -C "${wpDir}" clean -fdx
    else
      ${pkgs.coreutils}/bin/mkdir -p "${wpDir}"
      tmp="$(${pkgs.coreutils}/bin/mktemp -d)"
      trap '${pkgs.coreutils}/bin/rm -rf "$tmp"' EXIT
      ${pkgs.git}/bin/git clone --depth 1 --branch "${wpRepoBranch}" "${wpRepoUrl}" "$tmp/repo"
      ${pkgs.rsync}/bin/rsync -a --delete "$tmp/repo/" "${wpDir}/"
    fi

    echo "✅ Wallpapers updated in ${wpDir}"
  '';
in {
  home.packages = with pkgs; [git rsync];

  systemd.user.services.waypaper-fetch = {
    Unit = {
      Description = "Fetch wallpapers from remote repo";
      After = ["hyprland-env.service" "network-online.target"];
      Wants = ["network-online.target"];
      PartOf = ["hyprland-session.target"];
    };
    Service = {
      Type = "oneshot";
      ExecStart = fetchScript; # <— Belangrijk: Nix-derivation, niet ~/.local/bin
      TimeoutStartSec = "3min";
      Environment = [
        "XDG_CONFIG_HOME=%h/.config"
        "HOME=%h"
      ];
    };
    Install.WantedBy = ["hyprland-session.target"];
  };

  systemd.user.timers.waypaper-fetch = {
    Unit.Description = "Periodic wallpaper fetch";
    Timer = {
      OnBootSec = "2m";
      OnUnitActiveSec = "6h";
      Unit = "waypaper-fetch.service";
    };
    Install.WantedBy = ["timers.target"];
  };
}
