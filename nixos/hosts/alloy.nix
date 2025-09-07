{inputs, ...}: {
  networking.hostName = "alloy";

  desktop.enableGnome = true;
  desktop.enableKde = true;
  desktop.enableHyperland = true;

  services.displayManager.gdm.enable = true;
  services.displayManager.gdm.wayland = true;
  services.displayManager.defaultSession = "hyprland";

  # Definine host-specifi sshUsers
  sshUsers = ["eelco"];
  configuredUsers = ["eelco"];

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
      ../modules/secrets/alloy-eelco.nix
    ]
    ++
    # 🛠️ Services
    [
      ../modules/services/ssh-client-keys.nix
    ]
    ++
    # 💻 Hardware and disk setup
    [
      ../modules/hardware/bluetooth.nix
      ../hardware/alloy/configuration.nix
      ../disks/alloy.nix
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
