{inputs, ...}: {
  networking.hostName = "ellie";

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
      ../modules/secrets/ellie-eelco.nix
    ]
    ++
    # 🛠️ Services
    [
      ../modules/services/ssh-client-keys.nix
    ]
    ++
    # 💻 Hardware and disk setup
    [
      ../hardware/ellie/configuration.nix
      ../disks/ellie.nix
    ]
    ++
    # 🧩 External modules
    [
      inputs.disko.nixosModules.disko
      inputs.home-manager.nixosModules.home-manager
    ];
}
