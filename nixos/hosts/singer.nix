{ inputs, ... }:

{

  networking.hostName = "singer";

  desktop.enableGnome = true;
  desktop.enableKde = false;
  desktop.enableHyperland = false;

  # Definine host-specifi sshUsers
  sshUsers = [ "eelco" "por" ];

  imports =
    # 🧱 Basic modules
    [
      ../modules/common.nix
      ../modules/profiles/desktop.nix
      ../modules/home-manager.nix
    ]

    ++

    # 🔐 Secrets
    [
      ../modules/secrets/default.nix
      ../modules/secrets/ssh-key-eelco.nix
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

    # 🏠 Home-manager configurations
    [
      ../home/eelco.nix
      ../home/por.nix
    ]

    ++

    # 🧩 External modules
    [
      inputs.disko.nixosModules.disko
      inputs.home-manager.nixosModules.home-manager
    ];

}
