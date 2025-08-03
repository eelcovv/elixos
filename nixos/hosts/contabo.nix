{inputs, ...}: {
  networking.hostName = "contabo";

  desktop.enableGnome = false;
  desktop.enableKde = true;
  desktop.enableHyperland = true;

  # Definine host-specifi sshUsers
  sshUsers = ["eelco"];
  configuredUsers = ["eelco"];

  imports =
    # 🧱 Basic modules
    [
      ../modules/common.nix
      ../modules/profiles/rescue-server-software.nix
      ../modules/profiles/desktop-options.nix
      ../modules/profiles/desktop-configs.nix
      ../modules/profiles/desktop-software.nix
      ../modules/home-manager.nix
    ]
    ++
    # 🛠️ Services
    [
      ../modules/services/ssh-client-keys.nix
    ]
    ++
    # 💻 Hardware and disk setup
    [
      ../hardware/contabo/configuration.nix
      ../disks/contabo.nix
    ]
    ++
    # 👤 Users
    [
      ../users/eelco.nix
    ]
    ++
    # 🧩 External modules
    [
      inputs.disko.nixosModules.disko
      inputs.home-manager.nixosModules.home-manager
    ];
}
