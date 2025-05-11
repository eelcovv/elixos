# Show the commands
default:
  just --list --unsorted

# ========== VM INSTALLATION WORKFLOW ==========

# --- On your own laptop ---

#  Install the required packages
vm_prerequist_install:
  nix-shell -p qemu qemu-utils OVMF rage sops

# 1. Download the ISO, OVMF files, and create an empty disk. 
vm_prepare:
  mkdir -p $HOME/vms/nixos
  curl -L -o $HOME/vms/nixos/nixos-minimal.iso https://channels.nixos.org/nixos-24.11/latest-nixos-minimal-x86_64-linux.iso
  cp -v $(nix-build '<nixpkgs>' -A OVMF.fd)/FV/OVMF_CODE.fd $HOME/vms/nixos/
  cp -v $(nix-build '<nixpkgs>' -A OVMF.fd)/FV/OVMF_VARS.fd $HOME/vms/nixos/uefi_vars.fd
  chmod 644 $HOME/vms/nixos/*.fd
  qemu-img create -f qcow2 $HOME/vms/nixos/nixos-vm.qcow2 30G
  @echo "VM drive has been created. You can now run the installer with 'just vm_run_installer'."

# 2. Start VM from the ISO (run installer)
vm_run_installer:
  qemu-system-x86_64 \
    -enable-kvm \
    -m 8G \
    -drive if=pflash,format=raw,readonly=on,file=$HOME/vms/nixos/OVMF_CODE.fd \
    -drive if=pflash,format=raw,file=$HOME/vms/nixos/uefi_vars.fd \
    -drive if=virtio,file=$HOME/vms/nixos/nixos-vm.qcow2,format=qcow2 \
    -cdrom $HOME/vms/nixos/nixos-minimal.iso \
    -boot d \
    -nic user,model=virtio-net-pci,hostfwd=tcp::2222-:22
  @echo "Installer has started. You can now login with `ssh -p 2222 nixos@localhost` (run `ssh-keygen -R "[localhost]:2222"` to clear the keys first )"

# --- Inside the live VM (via SSH or console) ---

# 3. Partition the disk in the VM
vm_partition:
  sudo nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko -- --mode zap_create_mount ./nixos/modules/disk-layouts/generic-vm.nix
  @echo "Partioning is done. You can now run vm_install"

# Copy Age private key from local ~/.config/sops/age/keys.txt to remote live installer
# Usage: just push-key
# Push the Age private key to the live installer via localhost:2222
# Step 1: scp key from host to live installer
push-key:
	scp -P 2222 ~/.config/sops/age/keys.txt nixos@localhost:/home/nixos/keys.txt

# Step 2: prepare /root/.config/sops/age/keys.txt on the live installer
install-root-key:
	sudo mkdir -p /root/.config/sops/age
	sudo cp /home/nixos/keys.txt /root/.config/sops/age/keys.txt
	sudo chmod 600 /root/.config/sops/age/keys.txt
	@echo "✅ Age private key ready for nixos-install"

# Clone elixos repo on the live installer
clone-repo:
	ssh -p 2222 nixos@localhost 'git clone git@github.com:eelco/elixos.git || true'

# Run install-root-key inside cloned repo on live installer
remote-install-root-key:
	ssh -p 2222 nixos@localhost 'cd elixos && just install-root-key'

# Full bootstrap sequence
bootstrap-vm:
	@echo "📡 Copying Age key to live installer (localhost:2222)..."
	just push-key
	@echo "📂 Cloning elixos repo on live installer..."
	just clone-repo
	@echo "🔑 Installing Age key inside live installer..."
	just remote-install-root-key
	@echo "🚀 Running NixOS installation..."
	ssh -p 2222 nixos@localhost 'cd elixos && just vm_install'
	@echo "✅ VM bootstrap complete!"


# 5. Install NixOS on the disk in the VM
vm_install:
  sudo nixos-install --flake .#generic-vm

  @echo "Installation is done. You can now run the installed vm form your host with vm_run"

# --- Back on your own laptop ---

# 6. Start VM from the installed disk
vm_run:
  qemu-system-x86_64 \
    -enable-kvm \
    -m 8G \
    -smp 2 \
    -cpu host \
    -drive if=pflash,format=raw,readonly=on,file=$HOME/vms/nixos/OVMF_CODE.fd \
    -drive if=pflash,format=raw,file=$HOME/vms/nixos/uefi_vars.fd \
    -drive if=virtio,file=$HOME/vms/nixos/nixos-vm.qcow2,format=qcow2 \
    -boot c \
    -nic user,model=virtio-net-pci,hostfwd=tcp::2222-:22


# 7. (Optional) Start VM with GPU support (for faster desktop)
vm_run_gpu:
  qemu-system-x86_64 \
    -enable-kvm \
    -m 8G \
    -cpu host \
    -smp 4 \
    -device virtio-vga,virgl=on \
    -device virtio-tablet \
    -device virtio-keyboard-pci \
    -display gtk,gl=on \
    -drive if=pflash,format=raw,readonly=on,file=$HOME/vms/nixos/OVMF_CODE.fd \
    -drive if=pflash,format=raw,file=$HOME/vms/nixos/uefi_vars.fd \
    -drive if=virtio,file=$HOME/vms/nixos/nixos-vm.qcow2,format=qcow2 \
    -boot c \
    -nic user,model=virtio-net-pci

# Remove the VM files
vm_reset:
    rm -rv $HOME/vms
    @echo "VM files have been removed. You can now start over with 'just vm_prepare'."

# Quick test-build VM for Generic-vm
vm_build_generic-vm:
  nixos-rebuild build-vm --flake .#generic-vm

# ========== SYSTEM BUILD & TESTING ==========

# --- On your own laptop ---

# Rebuild the Tongfang laptop locally
local_tongfang:
  sudo nixos-rebuild switch --show-trace --flake .#tongfang

# Quick test-build VM for Tongfang
vm_build_tongfang:
  nixos-rebuild build-vm --flake .#tongfang

# Quick test-build VM for Singer
vm_build_singer:
  nixos-rebuild build-vm --flake .#singer

# Quick test-build VM for Generic-vm
vm_switch_generic-vm-eelco:
  sudo nixos-rebuild switch --flake .#generic-vm

# ========== SYSTEM MAINTENANCE ==========

# --- On your own laptop ---

# Update all flake inputs
update:
  nix flake update

# Garbage collect old versions
clean:
  nix-collect-garbage

# Format all Nix files
fmt:
  pre-commit run --all-files

# ========== ENCRYTION ==========
# Encrypt ~/.ssh/id_ed25519 to SOPS-YAML
encrypt-key:
	@echo "🔐 Converting ~/.ssh/id_ed25519 to YAML format..."
	@mkdir -p nixos/secrets
	@echo "id_ed25519: |" > nixos/secrets/generic-vm-secrets.yaml
	@cat ~/.ssh/id_ed25519 | sed 's/^/  /' >> nixos/secrets/generic-vm-secrets.yaml
	@echo "🔒 Encrypting with sops..."
	@nix shell nixpkgs#sops -c sops -e -i nixos/secrets/generic-vm-secrets.yaml
	@echo "✅ Secret encrypted and saved to nixos/secrets/generic-vm-secrets.yaml"

# Show decrypted contents of secrets (terminal only)
show-key:
	@nix shell nixpkgs#sops -c sops -d nixos/secrets/generic-vm-secrets.yaml

# Decrypte the file to ~/.ssh/id_ed25519
decrypt-key:
	@echo "🔓 Decrypting to ~/.ssh/id_ed25519..."
	@nix shell nixpkgs#sops -c sops -d nixos/secrets/generic-vm-secrets.yaml > ~/.ssh/id_ed25519
	@chmod 400 ~/.ssh/id_ed25519
	@echo "✅ Written and secured: ~/.ssh/id_ed25519"


# ========== SSH SETUP ==========
#  Enable SSH on a live NixOS system (VM or real machine)
live_setup_ssh:
  sudo passwd nixos
  sudo systemctl start sshd
  ip a | grep 'inet ' | grep -v 127.0.0.1 || true
  @echo "SSH server is ready. You can now scp your age-secret-key.txt file to this machine."