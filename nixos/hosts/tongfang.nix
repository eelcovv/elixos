{inputs, ...}: {
  networking.hostName = "tongfang";

  desktop.enableGnome = true;
  desktop.enableKde = true;
  desktop.enableHyperland = true;

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
      ../modules/profiles/flatpak.nix
      ../modules/profiles/containers/podman.nix
      ../modules/lib/python-runtimes.nix
    ]
    ++
    # 🔐 Secrets
    [
      ../modules/secrets/tongfang-eelco.nix
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
      ../hardware/tongfang/configuration.nix
      ../disks/tongfang.nix
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
}
