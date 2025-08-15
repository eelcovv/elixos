{
  config,
  pkgs,
  lib,
  ...
}: {
  config = {
    ##########################################################################
    # Waybar — run it exactly once via systemd, bound to the Hyprland session
    #
    # Important:
    # - Do NOT start Waybar from hyprland.conf (no `exec`/`exec-once`).
    # - We only enable Waybar and let systemd handle lifecycle.
    # - All wallpaper/theme switching is handled elsewhere (your scripts).
    ##########################################################################
    programs.waybar.enable = true;

    # Pin package explicitly if you like; otherwise the default is fine.
    programs.waybar.package = pkgs.waybar;

    # Run Waybar as a user service and tie it to the Hyprland user target.
    # Your Hyprland module defines `systemd.user.targets."hyprland-session"`.
    programs.waybar.systemd.enable = true;
    programs.waybar.systemd.target = "hyprland-session.target";

    ##########################################################################
    # (Optional) Provide Waybar config/theme files via Home Manager.
    #
    # If you keep your Waybar theme files in your repo, you can expose them
    # here. Leave this block commented if you already manage them elsewhere
    # (e.g. your theme switcher writes to ~/.config/waybar/current/*).
    #
    # Example layout:
    #   home/modules/hyperland/waybar/themes/<theme>/(config.jsonc, modules.jsonc, style.css, colors.css)
    #
    # Uncomment and adjust paths as needed.
    ##########################################################################
    # xdg.configFile."waybar/themes/ml4w/config.jsonc".source =
    #   ./themes/ml4w/config.jsonc;
    # xdg.configFile."waybar/themes/ml4w/modules.jsonc".source =
    #   ./themes/ml4w/modules.jsonc;
    # xdg.configFile."waybar/themes/ml4w/dark/style.css".source =
    #   ./themes/ml4w/dark/style.css;
    # xdg.configFile."waybar/themes/ml4w/dark/colors.css".source =
    #   ./themes/ml4w/dark/colors.css;

    ##########################################################################
    # (Optional) Ship a minimal "current" scaffold if you want Waybar to have
    # something to load on very first boot. Your theme-switcher will later
    # replace these symlinks/files. Safe to omit if you already seed them in
    # another module.
    ##########################################################################
    # xdg.configFile."waybar/current/.keep".text = "";

    ##########################################################################
    # ⚠️ Do not declare *any* wallpaper-related options in this module.
    # The wallpaper options (hyprland.wallpaper.*) live exclusively in:
    #   home/modules/hyperland/waypaper/default.nix
    ##########################################################################
  };
}
