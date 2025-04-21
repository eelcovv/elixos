default:
    @just --list

# Activate local configuration
[group('main')]
local:
    nix run


# prepare vm installer
vm_prepare_install:
    mkdir -vp $HOME/vms
    curl -o $HOME/vms/nixos-minimal.iso -L https://channels.nixos.org/nixos-24.11/latest-nixos-minimal-x86_64-linux.iso
    cp -v $(nix-build '<nixpkgs>' -A OVMF.fd)/FV/OVMF_CODE.fd $HOME/vms/
    cp -v $(nix-build '<nixpkgs>' -A OVMF.fd)/FV/OVMF_VARS.fd $HOME/vms/uefi_vars.fd
    chmod 644 $HOME/vms/*.fd
    qemu-img create -f qcow2 $HOME/vms/nixos-vm.qcow2 30G



# start vm installer
vm_run_iso:
qemu-system-x86_64 \
  -enable-kvm \
  -m 16384 \
  -drive if=pflash,format=raw,readonly=on,file=$HOME/vms/OVMF_CODE.fd \
  -drive if=pflash,format=raw,file=$HOME/vms/uefi_vars.fd \
  -drive if=virtio,file=$HOME/vms/nixos-vm.qcow2,format=qcow2 \
  -cdrom $HOME/vms/nixos-minimal.iso \
  -boot d \
  -nic user,model=virtio-net-pci,hostfwd=tcp::2222-:22

# start vm vanaf disk
vm_run:
    qemu-system-x86_64 -enable-kvm -m 8192 -cpu host \
    -bios /home/eelco/vms/nixos/OVMF_CODE.fd \
    -drive if=pflash,format=raw,file=/home/eelco/vms/nixos/uefi_vars.fd \
    -drive file=/home/eelco/vms/nixos/nixos-vm.qcow2,format=qcow2 \
    -boot order=c -nic user,model=virtio-net-pci -display gtk


# Start de tongfang VM
vm_run_tongfang:
    qemu-system-x86_64 \
        -enable-kvm \
        -m 16384 \
        -cpu host \
        -smp 4 \
        -vga virtio \
        -device virtio-gpu-pci \
        -display gtk \
        -drive if=pflash,format=raw,readonly=on,file=$HOME/vms/nixos/OVMF_CODE.fd \
        -drive if=pflash,format=raw,file=$HOME/vms/nixos/uefi_vars.fd \
        -drive if=virtio,format=qcow2,file=$HOME/vms/nixos/nixos-vm.qcow2,cache=writeback,discard=on \
        -boot order=c \
        -nic user,model=virtio-net-pci


# Start de tongfang VM met GPU
vm_run_tongfang_gpu:
    qemu-system-x86_64 \
        -enable-kvm \
        -m 16384 \
        -cpu host \
        -smp 4 \
        -device virtio-vga,virgl=on \
        -device virtio-tablet \
        -device virtio-keyboard-pci \
        -display gtk,gl=on \
        -drive if=pflash,format=raw,readonly=on,file=$HOME/vms/nixos/OVMF_CODE.fd \
        -drive if=pflash,format=raw,file=$HOME/vms/nixos/uefi_vars.fd \
        -drive if=virtio,format=qcow2,file=$HOME/vms/nixos/nixos-vm.qcow2,cache=writeback,discard=on \
        -boot order=c \
        -nic user,model=virtio-net-pci


local-tongfang:
    sudo nixos-rebuild switch --show-trace --flake .#tongfang
 
# Build the vm of singer
vm_singer:
    nixos-rebuild build-vm --flake .#singer 

# Build the vm of tongfang
vm_tongfang:
    nixos-rebuild build-vm --flake .#tongfang 

# update the flakes
update:
    nix flake update 

# Run this before `nix run` to build the current configuration
[group('main')]
nom:
    , nom build --no-link .#nixosConfigurations.tongfang.config.system.build.toplevel

# Deploy to Beelink
[group('deploy')]
pureintent:
    nix run . pureintent

# Deploy to nginx gate
[group('deploy')]
gate:
    nix run . gate

# Clean the cache
clean:
    nix-collect-garbage

# Format the nix source tree
fmt:
    pre-commit run --all-files

# https://discourse.nixos.org/t/why-doesnt-nix-collect-garbage-remove-old-generations-from-efi-menu/17592/4
fuckboot:
    sudo nix-collect-garbage -d
    sudo /run/current-system/bin/switch-to-configuration boot
