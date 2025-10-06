{inputs, ...}: {
  networking.hostName = "singer";

  desktop.enableGnome = true;
  desktop.enableKde = true;
  desktop.enableHyperland = true;

  # Definine host-specifi sshUsers
  sshUsers = ["eelco" "por"];
  configuredUsers = ["eelco" "por"];

  imports =
    # 🧱 Basic modules
    [
      ../modules/common.nix
      ../modules/profiles/desktop-options.nix
      ../modules/profiles/desktop-configs.nix
      ../modules/profiles/desktop-software.nix
      ../modules/profiles/session.nix
      ../modules/profiles/flatpak.nix
      ../modules/profiles/containers/docker.nix
      ../modules/lib/python-runtimes.nix
    ]
    ++
    # 🔐 Secrets
    [
      ../modules/secrets/singer-eelco.nix
    ]
    ++
    # 🛠️ Services
    [
      ../modules/services/ssh-client-keys.nix
      ../modules/services/login.nix
      ../modules/services/vpn-entries.nix
    ]
    ++
    # 💻 Hardware and disk setup
    [
      ../modules/hardware/bluetooth.nix
      ../hardware/singer/configuration.nix
      ../disks/singer.nix
    ]
    ++
    # 🧩 External modules
    [
      inputs.disko.nixosModules.disko
      inputs.home-manager.nixosModules.home-manager
    ];
    # 👇 Enable Flatpak profile on this host (uses ../modules/profiles/flatpak.nix)
    profiles.flatpak = {
      enable = true;
      addSystemFlathub = true;
      portals.hyprland = true;
      portals.gtk = true;
      # Optional: install system-scope apps automatically:
      # systemApps = [ "org.paraview.ParaView" ];
    };

    profiles.session.seedRememberLast = {
      enable = true;
      mapping = {
        eelco = "hyprland";
        por = "plasma";
      };
    };
  }
