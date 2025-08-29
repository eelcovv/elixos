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
}
