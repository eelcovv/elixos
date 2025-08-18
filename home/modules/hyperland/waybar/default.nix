{
  config,
  pkgs,
  lib,
  ...
}: let
  # Waar Waypaper/Hyprpaper jouw wallpapers verwacht (sluit aan op jouw config)
  wpDir = "${config.xdg.configHome}/wallpapers";

  # Pas aan als jouw repo anders heet of op een andere branch staat:
  wpRepoUrl = "https://github.com/mylinuxforwork/wallpaper";
  wpRepoBranch = "main";

  # Robuust fetch-script met juiste shebang naar Nix-bash
  fetchScript = pkgs.writeShellScript "fetch-wallpapers.sh" ''
    set -euo pipefail

    echo "📥 Downloading wallpapers from ${wpRepoUrl} ..."
    export GIT_TERMINAL_PROMPT=0
    export GIT_ASKPASS=true

    # Shallow update naar ${wpDir}; indien nog niet gecloned: snelle clone + rsync
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
  # Optioneel: je hoeft git/rsync/curl niet in PATH te zetten omdat we Nix-paden gebruiken,
  # maar het is handig ze ook als package te hebben.
  home.packages = with pkgs; [git rsync];

  # Eénduidige user-unit die Bash uit de Nix store gebruikt en genoeg timeout heeft.
  systemd.user.services.waypaper-fetch = {
    Unit = {
      Description = "Fetch wallpapers from remote repo";
      After = ["hyprland-env.service" "network-online.target"];
      Wants = ["network-online.target"];
      PartOf = ["hyprland-session.target"];
    };
    Service = {
      Type = "oneshot";
      ExecStart = fetchScript; # correcte shebang via pkgs.writeShellScript
      TimeoutStartSec = "3min"; # verhoog timeout
      # Zorg dat we dezelfde env hebben als je sessie:
      Environment = [
        "XDG_CONFIG_HOME=%h/.config"
        "HOME=%h"
      ];
    };
    Install = {WantedBy = ["hyprland-session.target"];};
  };

  # (Optioneel) Periodieke update, bv. elke 6 uur
  systemd.user.timers.waypaper-fetch = {
    Unit = {Description = "Periodic wallpaper fetch";};
    Timer = {
      OnBootSec = "2m";
      OnUnitActiveSec = "6h";
      Unit = "waypaper-fetch.service";
    };
    Install = {WantedBy = ["timers.target"];};
  };
}
