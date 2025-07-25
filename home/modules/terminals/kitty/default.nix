{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 12;
    };
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
    extraConfig = ''
      include ${config.xdg.configHome}/kitty/settings/kitty-cursor-trail.conf
      include ${config.xdg.configHome}/kitty/colors-wallust.conf
      include ${config.xdg.configHome}/kitty/colors-matugen.conf
      include ${config.xdg.configHome}/kitty/custom.conf
    '';
  };

  # Installeer font als nog niet aanwezig
  home.packages = with pkgs; [
    (nerdfonts.override {fonts = ["JetBrainsMono"];})
  ];

  # Declaratief meegekopieerde configuratiebestanden
  xdg.configFile."kitty/kitty.conf".source = ./kitty.conf;
  xdg.configFile."kitty/custom.conf".source = ./custom.conf;
  xdg.configFile."kitty/colors-wallust.conf".source = ./colors-wallust.conf;
  xdg.configFile."kitty/colors-matugen.conf".source = ./colors-matugen.conf;
  xdg.configFile."kitty/settings/kitty-cursor-trail.conf".source = ./settings/kitty-cursor-trail.conf;
}
