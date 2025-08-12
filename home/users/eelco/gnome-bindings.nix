{
  config,
  pkgs,
  lib,
  ...
}: {
  dconf.settings = {
    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5/"
      ];
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      name = "Ghostty Console";
      command = "ghostty";
      binding = "<Super>t";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
      name = "Google Chrome";
      command = "google-chrome-stable";
      binding = "<Super>b";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
      name = "VSCode";
      command = "code";
      binding = "<Super>c";
    };

    # custom3 is vrijgelaten (bestond nog niet in je file)
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4" = {
      name = "WasIstLos";
      command = "wasistlos";
      binding = "<Super><Shift>w";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5" = {
      name = "KeeWeb";
      command = "keeweb";
      binding = "<Super>k";
    };
  };
}
