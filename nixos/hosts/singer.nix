{ inputs, ... }:

{

  networking.hostName = "singer";

  desktop.enableGnome = false;
  desktop.enableKde = true;
  desktop.enableHyperland = true;

  # Definine host-specifi sshUsers
  sshUsers = [ "eelco" "por" ];
  configuredUsers = [ "eelco" "por"];


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
        ../modules/secrets/singer-eelco.nix
    ]

    ++
    # 🛠️ Services
    [
      ../modules/services/ssh-client-keys.nix
    ]

    ++

    # 💻 Hardware and disk setup
    [
      ../hardware/singer.nix
      ../disks/singer.nix
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
