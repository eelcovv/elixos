{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkMerge [
    # Fonts
    (import ../fonts/default.nix {inherit pkgs;}).config

    # GNOME
    (lib.mkIf config.desktop.enableGnome (
      (import ./gnome.nix {inherit lib pkgs;}).config
    ))

    # KDE Plasma
    (lib.mkIf config.desktop.enableKde (
      lib.mkMerge [
        (import ./kde.nix {inherit lib pkgs config;}).config
        (import ./wayland-session.nix {inherit lib pkgs config;})
        (import ./start-keyring-daemon.nix {inherit lib pkgs config;})
      ]
    ))

    # Hyprland
    (lib.mkIf config.desktop.enableHyperland (
      lib.mkMerge [
        (import ./hyperland.nix {inherit lib pkgs config;}).config
        (import ./wayland-session.nix {inherit lib pkgs config;})
        (import ./start-keyring-daemon.nix {inherit lib pkgs config;})
      ]
    ))
    # GDM + SSH prompt
    (lib.mkIf (config.desktop.enableGnome || config.desktop.enableKde || config.desktop.enableHyperland) {
      services.displayManager = {
        gdm = {
          enable = true;
          wayland = lib.mkForce false;
        };
        sessionPackages = [
          (pkgs.stdenv.mkDerivation {
            name = "plasma-x11-session";
            phases = ["installPhase"];
            installPhase = ''
                    mkdir -p $out/share/xsessions
                    cat > $out/share/xsessions/plasma-x11.desktop <<EOF
              [Desktop Entry]
              Version=1.0
              Type=XSession
              Exec=${pkgs.kdePackages.plasma-workspace}/bin/startplasma-x11
              TryExec=${pkgs.kdePackages.plasma-workspace}/bin/startplasma-x11
              Name=KDE Plasma (X11)
              DesktopNames=KDE
              EOF
            '';
            passthru.providedSessions = ["plasma-x11"];
          })
        ];

        defaultSession = "plasma-x11";

        autoLogin = {
          enable = false;
          user = null;
        };
      };

      programs.ssh.askPassword = "${pkgs.openssh}/libexec/ssh-askpass";
    })
  ];
}
