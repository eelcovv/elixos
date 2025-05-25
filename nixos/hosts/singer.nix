{ inputs, ... }:

{

  networking.hostName = "singer";

  desktop.enableGnome = true;
  desktop.enableKde = true;
  desktop.enableHyperland = true;

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
      ../modules/secrets/bootstrap-agekey.nix
      ../modules/secrets/default.nix
      ../modules/secrets/singer-eelco.nix
      ../modules/secrets/singer-por.nix
    ]

    ++

    # ⚙️ Services
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
