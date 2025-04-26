# Show the commands
default:
  just --list --unsorted

# ========== VM INSTALLATION WORKFLOW ==========

# --- On your own laptop ---

#  nix-shell -p qemu qemu-utils OVMF first
vm_prerequist_install:
  nix-shell -p qemu qemu-utils OVMF just

# 1. Download the ISO, OVMF files, and create an empty disk. 
vm_prepare:
  mkdir -p $HOME/vms/nixos
  curl -L -o $HOME/vms/nixos/nixos-minimal.iso https://channels.nixos.org/nixos-24.11/latest-nixos-minimal-x86_64-linux.iso
  cp -v $(nix-build '<nixpkgs>' -A OVMF.fd)/FV/OVMF_CODE.fd $HOME/vms/nixos/
  cp -v $(nix-build '<nixpkgs>' -A OVMF.fd)/FV/OVMF_VARS.fd $HOME/vms/nixos/uefi_vars.fd
  chmod 644 $HOME/vms/nixos/*.fd
  qemu-img create -f qcow2 $HOME/vms/nixos/nixos-vm.qcow2 50G
  echo "VM drive has been created. You can now run the installer with 'just vm_run_installer'."

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
  echo "Installer has started. You can now login with `ssh -p 2222 nixos@localhost` (run `ssh-keygen -R "[localhost]:2222"` to clear the keys first )"

# --- Inside the live VM (via SSH or console) ---

# 3. Partition the disk in the VM
vm_partition:
  sudo nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko -- --mode zap_create_mount ./nixos/modules/disk-layouts/generic-vm.nix
  echo "Partioning is done. You can now run `vm_install`"

# 4. Install NixOS on the disk in the VM
vm_install:
  sudo nixos-install --flake .#generic-vm
  echo "Installation is done. You can now logout and close the VM-installer and start the vm with `vm_run`"

# --- Back on your own laptop ---

# 5. Start VM from the installed disk
vm_run:
  qemu-system-x86_64 \
    -enable-kvm \
    -m 8G \
    -drive if=pflash,format=raw,readonly=on,file=$HOME/vms/nixos/OVMF_CODE.fd \
    -drive if=pflash,format=raw,file=$HOME/vms/nixos/uefi_vars.fd \
    -drive if=virtio,file=$HOME/vms/nixos/nixos-vm.qcow2,format=qcow2 \
    -boot c \
    -nic user,model=virtio-net-pci,hostfwd=tcp::2222-:22

# 6. (Optional) Start VM with GPU support (for faster desktop)
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
    echo "VM files have been removed. You can now start over with 'just vm_prepare'."

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
