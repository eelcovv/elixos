{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.kitty = {
    enable = true;

    # Only real "machine" segments here, rest in kitty.conf
    settings = {
      # Remote control always on
      allow_remote_control = "yes";
      # Let Kitty choose a socket and export kitty_listen_on
      # (With a hard path is also possible: "Unix:/TMP/Kitty-RC")
      listen_on = "unix:/tmp/kitty";
    };

    # Optional: A safe fallback if Matuit fails
    themeFile = "One Half Dark";
  };

  # Config files that are managed declaratively.
  # Note: colors-matugen.conf is *not* declared here;
  # it should be written by Matugen at runtime.
  xdg.configFile."kitty/kitty.conf".source = ./kitty.conf;
  xdg.configFile."kitty/custom.conf".source = ./custom.conf;
  xdg.configFile."kitty/panic.conf".source = ./panic.conf;
  xdg.configFile."kitty/colors-wallust.conf".source = ./colors-wallust.conf;
  xdg.configFile."kitty/settings/kitty-cursor-trail.conf".source = ./settings/kitty-cursor-trail.conf;
}
