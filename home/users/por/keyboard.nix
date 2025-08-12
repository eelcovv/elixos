{
  config,
  pkgs,
  lib,
  ...
}: {
  # Hyprland keyboard-config (wordt ingelezen door je Hyprland setup)
  xdg.configFile."hypr/conf/keyboard-local.conf".text = ''
    input {
      kb_layout = us,th
      kb_options = grp:alt_shift_toggle
    }
  '';

  # GNOME keyboard-layout via dconf
  dconf.settings = {
    "org/gnome/desktop/input-sources" = {
      sources = [
        (lib.gvariant.mkTuple ["xkb" "us"])
        (lib.gvariant.mkTuple ["xkb" "th"])
      ];
      xkb-options = ["grp:alt_shift_toggle"];
    };
  };
}
