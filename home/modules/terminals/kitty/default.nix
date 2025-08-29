{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.kitty = {
    enable = true;

    # Appearance and behavior managed declaratively.
    # Copy/paste settings are kept in custom.conf only
    # to avoid duplicate or conflicting definitions.
    settings = {
      remember_window_size = false;
      initial_window_width = 950;
      initial_window_height = 500;

      cursor_blink_interval = 0.5;
      cursor_stop_blinking_after = 1;

      scrollback_lines = 2000;
      wheel_scroll_min_lines = 1;
      enable_audio_bell = false;

      window_padding_width = 10;
      hide_window_decorations = "yes";
      background_opacity = "0.7";
      dynamic_background_opacity = "yes";
      confirm_os_window_close = 0;

      selection_foreground = "none";
      selection_background = "none";
    };
  };

  # Config files that are managed declaratively.
  # Note: colors-matugen.conf is *not* declared here;
  # it should be written by Matugen at runtime.
  xdg.configFile."kitty/kitty.conf".source = ./kitty.conf;
  xdg.configFile."kitty/custom.conf".source = ./custom.conf;
  xdg.configFile."kitty/colors-wallust.conf".source = ./colors-wallust.conf;
  xdg.configFile."kitty/settings/kitty-cursor-trail.conf".source = ./settings/kitty-cursor-trail.conf;
}
