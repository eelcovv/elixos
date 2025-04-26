default:
  @just --summary

# ========== VM INSTALLATIE WORKFLOW ==========

# --- Op je eigen laptop ---

# 1. Download ISO, OVMF bestanden, maak lege disk
vm_prepare:
  mkdir -p $HOME/vms/nixos
  curl -L -o $HOME/vms/nixos/nixos-minimal.iso https://channels.nixos.org/nixos-24.11/latest-nixos-minimal-x86_64-linux.iso
  cp -v $(nix-build '<nixpkgs>' -A OVMF.fd)/FV/OVMF_CODE.fd $HOME/vms/nixos/
  cp -v $(nix-build '<nixpkgs>' -A OVMF.fd)/FV/OVMF_VARS.fd $HOME/vms/nixos/uefi_vars.fd
  chmod 644 $HOME/vms/nixos/*.fd
  qemu-img create -f qcow2 $HOME/vms/nixos/nixos-vm.qcow2 30G

# 2. Start VM vanaf ISO (installer draaien)
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

# --- Binnen de live-VM (via SSH of console) ---

# 3. Partitioneer de schijf in de VM
vm_partition:
  sudo nix run github:nix-community/disko -- --mode zap_create_mount ./nixos/disks/qemu-vm.nix

# 4. Installeer NixOS op de disk in de VM
vm_install:
  sudo nixos-install --flake .#generic-vm

# --- Terug op je eigen laptop ---

# 5. Start VM vanaf de geinstalleerde disk
vm_run:
  qemu-system-x86_64 \
    -enable-kvm \
    -m 8G \
    -drive if=pflash,format=raw,readonly=on,file=$HOME/vms/nixos/OVMF_CODE.fd \
    -drive if=pflash,format=raw,file=$HOME/vms/nixos/uefi_vars.fd \
    -drive if=virtio,file=$HOME/vms/nixos/nixos-vm.qcow2,format=qcow2 \
    -boot c \
    -nic user,model=virtio-net-pci,hostfwd=tcp::2222-:22

# 6. (optioneel) Start VM met GPU ondersteuning (voor snellere desktop)
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

# ========== SYSTEM BUILD & TESTING ==========

# --- Op je eigen laptop ---

# Rebuild Tongfang laptop lokaal
local_tongfang:
  sudo nixos-rebuild switch --show-trace --flake .#tongfang

# Snelle test-build VM voor Tongfang
vm_build_tongfang:
  nixos-rebuild build-vm --flake .#tongfang

# Snelle test-build VM voor Singer
vm_build_singer:
  nixos-rebuild build-vm --flake .#singer

# ========== DEPLOYMENT ==========

# --- Op je eigen laptop ---

# Deploy naar server 'pureintent'
deploy_pureintent:
  nix run . pureintent

# Deploy naar server 'gate'
deploy_gate:
  nix run . gate

# ========== SYSTEM MAINTENANCE ==========

# --- Op je eigen laptop ---

# Update alle flake inputs
update:
  nix flake update

# Garbage collect oude versies
clean:
  nix-collect-garbage

# Format alle Nix bestanden
fmt:
  pre-commit run --all-files
