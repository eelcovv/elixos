default:
    @just --list

# Activate local configuration
[group('main')]
local:
    nix run

# start vm installer
vm_run_iso:
    qemu-system-x86_64 -enable-kvm -m 8192 -cpu host \
    -bios /home/eelco/vms/nixos/OVMF_CODE.fd \
    -drive if=pflash,format=raw,file=/home/eelco/vms/nixos/uefi_vars.fd \
    -drive file=/home/eelco/vms/nixos/nixos-vm.qcow2,format=qcow2 \
    -cdrom /home/eelco/vms/nixos/nixos-vm.iso/nixos-minimal-24.11.716947.26d499fc9f1d-x86_64-linux.iso \
    -boot order=d -nic user,model=virtio-net-pci -display gtk

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
