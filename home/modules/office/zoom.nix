{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  # Last Zoom version with working Wayland screen sharing
  zoomVersion = "6.0.2.4680";

  # This is nixpkgs 24.05 from the flake input which has the required pipewire v1.0.7 for older Zoom
  stablePkgs = inputs.nixpkgs-stable.legacyPackages.${pkgs.system};

  zoom-us-custom = (pkgs.zoom-us.override {pipewire = stablePkgs.pipewire;}).overrideAttrs (oldAttrs: rec {
    version = zoomVersion;
    src = pkgs.fetchurl {
      url = "https://zoom.us/client/${version}/zoom_x86_64.pkg.tar.xz";
      hash = "sha256-027oAblhH8EJWRXKIEs9upNvjsSFkA0wxK1t8m8nwj8=";
    };
  });
in {
  home.packages = [
    zoom-us-custom
  ];

  # Without disabling xwayland, fonts are pixelated and look like 💩
  xdg.configFile."zoomus.conf" = {
    text = ''
      [General]
      xwayland=false
      enableWaylandShare=true '';
  };
}
