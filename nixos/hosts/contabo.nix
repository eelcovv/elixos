{
  inputs,
  lib,
  ...
}: {
  networking.hostName = "contabo";

  desktop.enableGnome = false;
  desktop.enableKde = true;
  desktop.enableHyperland = false;

  services.displayManager.gdm.wayland = lib.mkForce false;

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
    ]
    ++
    # 🛠️ Services
    [
      ../modules/services/ssh-client-keys.nix
      ../modules/services/xrdp.nix
    ]
    ++
    # 💻 Hardware and disk setup
    [
      ../hardware/contabo/configuration.nix
    ]
    ++
    # 🧩 External modules
    [
      inputs.home-manager.nixosModules.home-manager
    ];
}
