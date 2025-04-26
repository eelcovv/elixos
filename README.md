# Eelco's Nixos configuration

## Introduction

This project contains the configuration for my Nixos setup.It is designed to support a ** Multi-user **, ** Multi-host ** system, which means that you can easily configure different users and systems.The configuration is modular and uses a ** flake ** for the management of Nixos installations, which ensures reusability and clarity when managing different hosts and users. 

## project structure

The configuration is divided into the following directories:
- ** `Modules/` **: contains all configuration modules that are reusable for different systems.
- ** `Common.nix` **: Contains settings that apply to all systems, such as user management, network configuration, and more.
- ** `Hosts/` **: Contains configurations for specific systems, such as laptops, servers, etc.
- ** `Users/` **: Contains configurations for different users, so that you can easily reuse users on different hosts.
-** `Hardware/` **: Contains hardware-specific configurations such as partitions and Luks encryption.

## Add a new host

To add a new host, you can follow the following steps:

### 1. Generate the hardware configuration for the new host

Use the "Nixos-Alense" command to make a hardware configuration for the new machine:
```shell
nixos-generate -c config
```
This generates a file `hardware configuration.nix` that you can use for your new host.

### 2. Make a new host configuration in the `hosts/` directory

Create a new `.nix 'file in the` hosts/`directory and configure the required settings for the new machine.For example, for a new laptop:
```nix
# hosts/new-laptop.nix
{ inputs, ... }:

{
  imports = [
    ../modules/common.nix
    ../hardware/new-laptop.nix
    ../users/users.nix
  ];

  networking.hostName = "new-laptop";
  # Voeg andere host-specifieke instellingen toe hier
}
```

### 3. Test the configuration with `Nixos rebuild` in a VM

To quickly test whether your configuration works, you can use `Nixos-Rebuild Build-VM`.This makes a virtual machine with your current configuration:

```shell
nixos-rebuild build-vm --flake .#new-laptop
```
This will start a VM with the configuration of the new host, which you can test quickly.

## Qemu-VM set up

For a more detailed test you can set up a full QEMU-VM.

First a global overview.We are going to do the following:

:

🧩 1. Setup in the live environment (via SSH)
1. You log in to the VM with SSH.

2. You create an SSH key and add it to your Github account.

3. You clone are your Eelco-Nixos repository to ~/Eelco-Nixos.

💾 2. Disko with disko
`` shell
SUDO NIX-Extra-Experimental Features 'Nix-Command Flakes' Run Github: Nix-Community/Disko----mod Zap_create_mount ./nixos/disks/qemu.nix
`` `

*-Mode Zap_Create_Mount knew the disk, creates the partitions, and Mount everything in the right places for Nixos-Install.

* Disko uses your config (qemu-vm.nix) to partition the disk (probably with Luks and/or LVM?).

🧱 3. Installation of Nixos
```shell
sudo nixos-install --flake .#tongfang-vm
`` `
* Installation from your flake, with Tongfang-VM as a hostname/system.

* Assuming that you have correctly defined Nixos Configuration.tongfang-VM in Flake.nix.

🔁 4. Restart in Qemu with UEFI + Forwarding
```shell
qemu-system-x86_64 \
  -enable-kvm \
  -m 16384 \
  -drive if=pflash,format=raw,readonly=on,file=$HOME/vms/OVMF_CODE.fd \
  -drive if=pflash,format=raw,file=$HOME/vms/uefi_vars.fd \
  -drive if=virtio,file=$HOME/vms/nixos-vm.qcow2,format=qcow2 \
  -nic user,model=virtio-net-pci,hostfwd=tcp::2222-:22
```
Final setup: with UEFI (OVMF), KVM acceleration, Virtio, and port-forwarding for SSH (Poort 2222 Local → 22 in the VM).

After this you could log in with:
```shell
ssh -p 2222 eelco@localhost
```


Follow these steps to make a Qemu VM:

1. Install the required packages

Install the required Qemu tools in your Nixos shell:
```shell
nix-shell -p qemu qemu-utils OVMF just
```
2. Make a virtual disk

Make a virtual disk for the VM:
```shell
qemu-img create -f qcow2 $HOME/vms/nixos-vm.qcow2 30G
```
To increase the disk later, use:

``` shell
qemu-img resize $HOME/vms/nixos-vm.qcow2 +20G
```

3. Mount the disk

Mount the disk so that you have access to the file system:
```shell
sudo mount $HOME/vms/nixos-vm.qcow2 $HOME/vms/nixos-vm
```
4. Make the required directories and clone the repository

Create the etc/ directory and clone your repository:

```shell
mkdir $HOME/vms/nixos-vm/etc
cd $HOME/vms/nixos-vm/etc
git clone git@github.com:eelcovv/eelco-nixos.git nixos
cd $HOME/vms/nixos-vm/etc
```
This cloning is also possible later when you start the VM in live-USB mode.

5. Install the ISO QEMU-VM

Note: this knew the contents of your virtual hard drive and starts with a new installation.

First download the ISO

```shell
curl -o $HOME/vms/nixos-minimal.iso -L https://channels.nixos.org/nixos-24.11/latest-nixos-minimal-x86_64-linux.iso
```

We will also use the open virtual machine firmware.We had already installed OVFM for this.Find the required files:

```shell
nix-build '<nixpkgs>' -A OVMF.fd
```
This gives a location such as `/nix/store/KW52jax4fH89AJ4GNK6PCLWIXAGCSDJR-OVMF-202411-FD '

You now have to copy the files.This is possible with

```shell
sudo cp -v $(nix-build '<nixpkgs>' -A OVMF.fd)/FV/OVMF_CODE.fd $HOME/vms/
```

You are the OVMF_Code.fd in your own VMS Directory

Now our Uefi_vars.fd must refer to the ovmf_vars.fd, so also copy
```shell
sudo cp -v $(nix-build '<nixpkgs>' -A OVMF.fd)/FV/OVMF_VARS.fd $HOME/vms/uefi_vars.fd
```



Start the VM with the Nixos ISO and couple the virtual disk:

```shell
qemu-system-x86_64 \
  -enable-kvm \
  -m 16384 \
  -drive if=pflash,format=raw,readonly=on,file=$HOME/vms/OVMF_CODE.fd \
  -drive if=pflash,format=raw,file=$HOME/vms/uefi_vars.fd \
  -drive if=virtio,file=$HOME/vms/nixos-vm.qcow2,format=qcow2 \
  -nic user,model=virtio-net-pci,hostfwd=tcp::2222-:22
```

This is the same as starting a Nixos Live-USB.

After starting, you change the password in the Qemu Terminal with:
```shell
passwd
```
6. Installing Nixos

Once the QEMU-VM has started, you can log in and perform the installation.Set a password:
```shell
ssh -p 2222 nixos@localhost
```
If you start your Qemu VM several times, you will get the Fingerprint Warning if you want to log in to the Local Machine with SSH.To clean it you can run
```shell
ssh-keygen -R "[localhost]:2222"
```
If you are logged in you create an SSH key with

Clone then your repository and configure the disk:
```shell
ssh-keygen
```

```shell
git clone git@github.com:eelcovv/eelco-nixos.git
```
And go into your repo with
```shell
cd eelco-nixos
```
7. Partition and mount the disk

Use Disko to partition and toot the disk:
```shell
sudo nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko -- --mode zap_create_mount ./nixos/disks/qemu-vm.nix
```
8. Perform the Nixos installation

Perform the installation with:
```shell
sudo nixos-install --flake .#tongfang-vm
```
9. Close the VM and restart

Close the Qemu-VM that runs the live ISO.You can restart the VM with:

```shell
qemu-system-x86_64 \
  -enable-kvm \
  -m 16384 \
  -drive if=pflash,format=raw,readonly=on,file=$HOME/vms/OVMF_CODE.fd \
  -drive if=pflash,format=raw,file=$HOME/vms/uefi_vars.fd \
  -drive if=virtio,file=$HOME/vms/nixos-vm.qcow2,format=qcow2 \
  -nic user,model=virtio-net-pci,hostfwd=tcp::2222-:22
```
10. Rebuild the boat system (possibly if you have changed)

Implement a rebuild from the boat system:
```shell
sudo nixos-rebuild boot --flake .#tongfang-vm
```

## Troubleshooting commands for finding labels

1. `LSBLK`: This gives an overview of the discs, partitions, file systems and labels, including the Mount Points.

2. `BLKID`: This command was used to request more detailed information about the partitions and their labels.
`Sudo BLKID /DEV /VDA2`
This gives the UUID, the file system type, the label and other metadata for a specific partition.

3. `Wipefs`: This was used to erase the existing partition table and file system data of a disk or partition, which is useful to restore a clean state.
`Sudo Wipefs -a /DEV /VDA`
This deletes all inscription information (such as GPT, MBR) from the disk.

4. `Partprobe 'and` udevadm trigger': these commands were used to inform the system of changes in the disk layout, so that the kernel and device manager can recognize the new partitions.
`Sudo Partprobe /DEV /VDA`
`Sudo Udevadm Trigger-subsystem-Match = Block`
`Sudo Udevadm Settle -Timeout 120`

5. `Sgdisk`: This is used for partitioning the disk, creating the GPT partition table and setting the partition settings such as size, name, type, and so on.
`Sgdisk -Clear /DEV /VDA`
`Sgdisk-align-end--new = 1:+512M-Partition -Guid = 1: R-Chahange-Not-admitted = 1: Disk-Main-boat-TypeCode = 1: EF00 /DEV /VDA`
`Sgdisk-align-end--annew = 2: 0: -0-Partition -Guid = 2: R -Change-admission = 2: Disk-Main-Disk-Main-Boot-TypeCode = 2: 8300 /DEV /VDA`

6. `Findmnt`: This was used to check whether the partitions have been properly mounted and whether the labels are recognized correctly.
`FindMNT/DEV/Disk/by-Partlabel/Disk-Main-Disk-Main-Groot/MNT/`

By carefully performing these steps, you could properly configure both the partitioning and the labels.

# Workflow Nixos Develop and test via Tongfang-VM

## 1. Adjust on Tongfang (Head-laptop)

- Adjust your configuration (e.g. `Nixos/Hosts/Tongfang-vm.nix`)
- Commit and Push to Github:

```shell
git add .
git commit -m "korte omschrijving"
git push
```

## 2. Updating and rebuilding on Tongfang-VM

* SSH to your VM (or open terminal in the VM)
* Make the latest changes and rebuild:

```shell
cd ~/eelco-nixos
git pull
sudo nixos-rebuild switch --flake .#tongfang
```
## 3. Testing
* Check if your change works as intended.
* If necessary Rollback:

```shell
sudo nixos-rebuild switch --rollback
```
## 4. If everything works

Only then the same push-pull-rebuild step on your real tongue laptop.

## Extra tips

* Use Sudo Nixos-Rebuild test-flake.#Tongfang if you want to temporarily try something without immediately activating.

* Make snapshots of your VM for major changes.

* Keep SSH open on Tongfang-VM so that it is easier to deploy.