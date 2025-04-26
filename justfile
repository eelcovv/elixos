default:
  @just --summary

# ========== VM WORKFLOW ==========

# 1. Download ISO en maak disk aan
vm_prepare:
  mkdir -p $HOME/vms/nixos
  curl -L -o $HOME/vms/nixos/nixos-minimal.iso https://channels.nixos.org/nixos-24.11/latest-nixos-minimal-x86_64-linux.iso
  cp -v $(nix-build '<nixpkgs>' -A OVMF.fd)/FV/OVMF_CODE.fd $HOME/vms/nixos/
  cp -v $(nix-build '<nixpkgs>' -A OVMF.fd)/FV/OVMF_VARS.fd $HOME/vms/nixos/uefi_vars.fd
  chmod 644 $HOME/vms/nixos/*.fd
  qemu-img create -f qcow2 $HOME/vms/nixos/nixos-vm.qcow2 30G

# 2. Start de installer ISO
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

# 3. Partitioneer de disk
vm_partition:
  sudo nix run github:nix-community/disko -- --mode zap_create_mount ./nixos/disks/qemu-vm.nix

# 4. Installeer NixOS
vm_install:
  sudo nixos-install --flake .#generic-vm

# 5. Start VM vanaf disk
vm_run:
  qemu-system-x86_64 \
    -enable-kvm \
    -m 8G \
    -drive if=pflash,format=raw,readonly=on,file=$HOME/vms/nixos/OVMF_CODE.fd \
    -drive if=pflash,format=raw,file=$HOME/vms/nixos/uefi_vars.fd \
    -drive if=virtio,file=$HOME/vms/nixos/nixos-vm.qcow2,format=qcow2 \
    -boot c \
    -nic user,model=virtio-net-pci,hostfwd=tcp::2222-:22

# 6. (optioneel) VM starten met GPU ondersteuning
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

# ========== BUILD & DEPLOY ==========

# Build de Tongfang lokaal
local_tongfang:
  sudo nixos-rebuild switch --show-trace --flake .#tongfang

# Snelle VM builds
vm_build_tongfang:
  nixos-rebuild build-vm --flake .#tongfang

vm_build_singer:
  nixos-rebuild build-vm --flake .#singer

# ========== SYSTEM MAINTENANCE ==========

# Update flake inputs
update:
  nix flake update

# Clean caches
clean:
  nix-collect-garbage

# Format broncode
fmt:
  pre-commit run --all-files
