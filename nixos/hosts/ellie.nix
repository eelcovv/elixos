{inputs, ...}: {
  networking.hostName = "ellie";

  desktop.enableGnome = true;
  desktop.enableKde = false;
  desktop.enableHyperland = false;

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
      ../modules/home-manager.nix
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
    # 👤 Users
    [
      ../users/eelco.nix
      ../users/por.nix
    ]
    ++
    # 🧩 External modules
    [
      inputs.disko.nixosModules.disko
      inputs.home-manager.nixosModules.home-manager
    ];
}
