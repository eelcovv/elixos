<p align="center">
  <img src="logo.png" alt="elixos logo" width="200"/>
</p>

# elixos

_The Declarative Cure for Your NixOS Headaches_

## 🌐 Introduction

**Elixos** is a modular, declarative NixOS configuration system for multi-host and multi-user environments. It leverages flakes and sops-nix for secure, reproducible, and extendable NixOS installations.

## 📁 Project Structure

    elixos/
    ├── flake.nix
    ├── flake.lock
    ├── justfile
    ├── nixos/
    │   ├── configuration.nix
    │   ├── disks/
    │   ├── hardware/
    │   ├── hosts/
    │   ├── home/
    │   ├── users/
    │   ├── modules/
    │   └── secrets/

## 🚀 Quick VM Installation Workflow

Use the following steps to quickly install a NixOS VM using QEMU.

### 🛠️ 1. Preparation on the Host

    just vm_prerequisites      # Install qemu, ovmf, rage, sops
    just vm_reset              # Remove old VM files
    just vm_prepare            # Download ISO and create VM disk
    just vm_run_installer      # Boot the live installer in QEMU

### 🔐 2. Bootstrap the VM from the Host

    just bootstrap-vm

This performs the following:

- Pushes your Age master key (keys.txt) to the live installer
- Pushes your repo to a bare Git repo on the VM
- Clones the repo into ~/elixos on the VM
- Installs the master key to /root/.config/sops/age/keys.txt
- Partitions the disk using disko
- Installs NixOS using the `generic-vm` configuration

### ▶️ 3. Boot the Installed VM

    just vm_run

### 🔑 4. SSH Login

    ssh -p 2222 eelco@localhost

If backspace does not work:

    export TERM=xterm

## 🧪 Development & Testing via VM

1. Modify your configuration (e.g. `hosts/tongfang.nix`, `modules/`, etc.)
2. Push to GitHub or directly to the live VM:

       git add . && git commit -m "Update" && git push

3. On the VM:

       cd ~/elixos
       git pull
       sudo nixos-rebuild switch --flake .#generic-vm

## 🔐 SOPS and SSH Key Management

Secrets like your SSH private key are stored as encrypted YAML files.

### 🔑 Create and Encrypt a New Key

    just make-secret generic-vm eelco

This creates:
- `~/.ssh/ssh_key_generic_vm_eelco`
- `nixos/secrets/generic-vm-eelco-secrets.yaml`

### 📦 Encryption Helpers

    just encrypt-key       # Convert ~/.ssh/id_ed25519 to encrypted YAML
    just show-key          # View decrypted secret
    just decrypt-key       # Restore ~/.ssh/id_ed25519 from secrets

## 🔧 Maintenance

    just update              # Update flake inputs
    just clean               # Run nix garbage collection
    just fmt                 # Format all .nix files
    just vm_reset            # Reset and clean VM setup
    just vm_build_generic-vm # Build the system only (no run)

## 🧩 Live Installer SSH Setup

For manual access to the live installer:

    just live_setup_ssh       # Start sshd and set root password
    just ssh_authorize        # Add your SSH key to the live VM

## 📈 Installation Flow Visualization

    Host (QEMU & Just)
           |
           v
    Live Installer (VM)
           |
           v
    Installed NixOS VM
           |
           v
    sops decrypt → ~/.ssh/id_ed25519
           |
           v
    Working SSH login

## 📚 Tips

- Add `export TERM=xterm` to your VM shell profile for better terminal compatibility.
- Use `just vm_run_gpu` for graphical output with virtio-vga and virgl.
- Create VM snapshots before major system changes.

Happy hacking with Elixos! 🧬
