<p align="center">
  <img src="logo.png" alt="elixos logo" width="200"/>
</p>

# elixos

_The Declarative Cure for Your NixOS Headaches_

## Introduction

This project contains the configuration for my Nixos setup.It is designed to support a ** Multi-user **, ** Multi-host ** system, which means that you can easily configure different users and systems.The configuration is modular and uses a ** flake ** for the management of Nixos installations, which ensures reusability and clarity when managing different hosts and users. 

## project structure

The configuration is divided into the following directories:
- ** `Modules/` **: contains all configuration modules that are reusable for different systems.
- ** `Common.nix` **: Contains settings that apply to all systems, such as user management, network configuration, and more.
- ** `Hosts/` **: Contains configurations for specific systems, such as laptops, servers, etc.
- ** `Users/` **: Contains configurations for different users, so that you can easily reuse users on different hosts.
-** `Hardware/` **: Contains hardware-specific configurations such as partitions and Luks encryption.

A visualisation of the structure is:

```text
elixos/
├── flake.nix
├── flake.lock
├── justfile
├── nixos/
│   ├── configuration.nix        # Entry point
│
│   ├── disks/                    # Host-specific disk configs
│   │   ├── tongfang.nix
│   │   ├── singer.nix
│   │   └── generic-vm.nix
│
│   ├── hardware/                 # Host-specific hardware configs
│   │   ├── tongfang.nix
│   │   ├── singer.nix
│   │   └── contabo.nix
│   │
│   ├── hosts/                    # Full host configs
│   │   ├── tongfang.nix
│   │   ├── singer.nix
│   │   └── contabo.nix
│   │
│   ├── home/                     # Per-user Home Manager configs
│   │   ├── eelco.nix
│   │   ├── por.nix
│   │   └── testuser.nix
│   │
│   ├── users/                    # System user configs (non-home-manager stuff)
│   │   ├── eelco.nix
│   │   ├── por.nix
│   │   └── testuser.nix
│   │
│   ├── modules/                  # Reusable modules
│   │   ├── common.nix             # Shared system config (timezone, locale, etc.)
│   │   ├── hardware/              # Hardware helpers (efi-boot, virtio)
│   │   │   ├── efi-boot.nix
│   │   │   └── virtio.nix
│   │   ├── home/                  # Home Manager helpers
│   │   │   ├── common-packages.nix
│   │   │   └── common-config.nix (optional later)
│   │   ├── profiles/              # System profiles (server, vm-host, desktop etc.)
│   │   │   └── vm-host.nix
│   │   ├── services/              # Generic services (like VM guest tools)
│   │   │   └── generic-vm.nix
│   │   └── disk-layouts/          # (optional) shared disk layouts
│   │       └── vm-standard.nix

```

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

3. You clone are your elixos repository to ~/elixos.

💾 2. Disko with disko

``` shell
SUDO NIX-Extra-Experimental Features 'Nix-Command Flakes' Run Github: Nix-Community/Disko----mod Zap_create_mount ./nixos/disks/qemu.nix
```

* Mode Zap_Create_Mount makes the disk, creates the partitions, and Mount everything in the right places for Nixos-Install.

* Disko uses your config (qemu-vm.nix) to partition the disk (probably with Luks and/or LVM?).

🧱 3. Installation of Nixos

```shell
sudo nixos-install --flake .#tongfang-vm
```

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

#### Follow these steps to make a Qemu VM:

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
git clone git@github.com:eelcovv/elixos.git nixos
cd $HOME/vms/nixos-vm/etc
```
This cloning is also possible later when you start the VM in live-USB mode.

5. Install the ISO QEMU-VM

Note: this makes the contents of your virtual hard drive and starts with a new installation.

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

Also, you want to get a clone of your elixos repo on the localhost.

If you are logged in on the VM, make a directory in the tmp

```shell
mkdir /tmp/elixos.git
cd elixos.igt
```

and initialise a bare repor

```shell
git init --bare
```

Now, in the repo of you host machine, add the remote:

```shell
git remote add localhost ssh://nixos@localhost:2222/tmp/elixos
```

and push to the remote

```shell
git push localhost main
```

and finally, clone your tmp repository to your home with

```shell
cd
git clone /tmp/elixos.git
cd elixos
git checkout main
```

To run the just file, just do

```shell
nix-shell -p just
```

And now you can run 
```shell
just vm_install
```

If you want to keep developping on the host and have to push a lot, add the local host to your ssh ageint. First check if the agent is running with 

```shell
eval "$(ssh-agent -s)"
```
then copy your id:

```shell
ssh-copy-id  -p 2222 nixos@localhost
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

### Workflow using the just file

All steps above have been added to the just file. I you want to set up a brand new vm, do the following steps

On the host machine you start with

1. `just vm_prerequist_install` to install the required packages
2. `just vm_reset` to remove the old vm
3. `just vm_prepare` to create the virtual hard drive and format it
4. `just vm_run_installer` to start the nixos live installer

At this point, you need to login to the live installer and make sure you transfer this repository to the live installer so you can continue there. Do the following 

In the QEMU window that has just started you do:

5. Set a passwd by typing `passwd` and set it to nixos or something simple

In a new terminal on your host, login to the vm live cd  by doing

6. `ssh-keygen -R "[localhost]:2222"` to clean the old ssh keys to the vm because they need to be renewed

7. `ssh -p 2222 nixos@localhost` to login in on your live nixos installer.

To transfer the repository to you live vm, do on you live-usb (in the terminal)

8. `mkdir /tmp/elixos.git` and `` to create an empty directory

9. `git init --bare /tmp/elixos.git` to create an empty bare repository we use a a remote server

Then on your host machine, add this folder with

10.  `git remote add localhost ssh://nixos@localhost:2222/tmp/elixos` to add the localhost
11. `ssh-copy-id  -p 2222 nixos@localhost`  to store your password so you dont have to type it each time
12. `git push localhost main` to push your repository 

Now, back on your live installer terminal, do 

13. `git clone -b main /tmp/elixos.git`   to clone your repo to your home folder
14. `cd elixos.git` to go to you cloned repository

At this point you should have a clone of your repository on the live usb. 

Now, only if you use ageix, copy you master age-secret-key.txt to your live nixos vm. So on your host machine, run
```shell
scp -P 2222 ~/.config/agenix/age-secret-key.txt nixos@localhost:~
```
Back on your live installer, put this age-secret-key.txt file into the same folder
```shell
mkdir -p ~/.config/agenix
mv ~/age-secret-key.txt ~/.config/agenix
```

With the master key in the default location, you should now be able to continue and install nixos. The agenix keys will be decrypted

On your live usb terminal do:

16. `nix-shell -p just` to install just so we can continue with our justfile
17. `just vm_partition` to partition the drive we have created in start 3 from your live nixos installer
18. `just vm_install` to install our generic-vm definition to the virtual hard drive

After installatie, you can close the QEMU terminal with the nixos live-usb installer
On your host machine do:

19. `just vm_run` to start up your freshly installed VM

20. You should now be able to login using `ssh eelco@localhost -p 2222`. If you have a   'backspace'-problem: a quick fix is `export TERM=xterm`


# 🔐 SOPS SSH 

## 🔐 How SOPS Machine Secrets Work

If you install a new hosts, normally you create new ssh key-pair using ssh-keygen. This
creates a ~/.ssh/id_ed25519 and ~/.ssh/id_ed25519.pub files as private and public key. 
The public key can be used to share with others, such as github. If you add your public, 
github can verify that it is you because you own the private key which is stored on you
own computer. Normally, you create a private/public key-pair for each host machine you 
own. For each host you need to add the public ssh key to the github (or any other service
where you want to login). 

Since we want to make a reproducable host using nixos, we need a way to store the 
ssh key-pair for a certain machine. This storing is done by agenix. With agenix you 
add your public key which you have created for a host to your public keys, and the
private keys is stored encrypted as an age file. 

In order to decrypt the age file for a host, you need to have a master private key. 
You can use this master key to decrypt your private age file for each machine. 

In the following proceedure, we start with creating a master key which will be used to
encrypt the age file. The master key is not added to your repository, but should 
carefully be kept in a save place. In this procedure, we are going to add the
master key as an attachment to a keepass database which is stored on a external cloud service. 
This allows us the retrieve the master key when we need to reproduce our machines, and thus to 
decrypt our encrypted age private keys.    

Let's start with setting up a age master key and use that to add a encrypted age key to 
our repository. 

# 🔐 SOPS-Nix setup steps

### STEP 1: Generate an Age key using rage (no agenix needed)
```shell
rage-keygen > ~/.config/sops/age/keys.txt
```

This commands also prints the public key which you need in step 2.

If you need the public key again, you can run

```shell
rage-keygen -y ~/.config/sops/age/keys.txt 
```

Note: this keys.txt file needs to be present  on each system where we want to decrypt the age files

### STEP 2: Create the .sops.yaml config in your repo root

This tells sops to encrypt matching keys using your Age public key
```shell
cat > .sops.yaml <<EOF
creation_rules:
  - encrypted_regex: ^id_ed25519
    key_groups:
      - age:
          - age1qxyzabc... # <-- your real public key
EOF
```

### STEP 3: Create the unencrypted secret YAML file (id_ed25519)
```shell
echo "id_ed25519: |" > nixos/secrets/generic-vm-secrets.yaml
cat ~/.ssh/id_ed25519 | sed 's/^/  /' >> nixos/secrets/generic-vm-secrets.yaml
```

### STEP 4: Encrypt the YAML file in-place using sops
```shell
sops -e -i nixos/secrets/generic-vm-secrets.yaml
```

### STEP 5: Reference the secrets in your NixOS config (e.g. modules/secrets/generic-vm.nix)
```shell
{
  sops.defaultSopsFile = ../../secrets/generic-vm-secrets.yaml;

  sops.age.keyFile = "/root/.config/sops/age/keys.txt"; # <-- required for decryption as root

  sops.secrets.id_ed25519 = {
    path = "/home/eelco/.ssh/id_ed25519";
    owner = "eelco";
    group = "users";
    mode = "0400";
  };
}
```

### STEP 6: Add a systemd service 

To generate the .pub file from the decrypted private key in add  a file
*modules/services/ssh-client-keys.nix*:

```nix
{ config, lib, pkgs, ... }:

let
  users = config.globalSshClientUsers or [];
in {
  systemd.services = lib.genAttrs users (user: {
    description = "Generate SSH public key for ${user}";
    wantedBy = [ "multi-user.target" ];
    after = [ "default.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = user;
      ExecStart = pkgs.writeShellScript "gen-id-ed25519-pub-${user}" ''
        if [ -f /home/${user}/.ssh/id_ed25519 ]; then
          ${pkgs.openssh}/bin/ssh-keygen -y -f /home/${user}/.ssh/id_ed25519 > /home/${user}/.ssh/id_ed25519.pub
        fi
      '';
    };
  });

  systemd.tmpfiles.rules = lib.flatten (map (user: [
    "d /home/${user}/.ssh 0700 ${user} users -"
    "f /home/${user}/.ssh/id_ed25519.pub 0644 ${user} users -"
  ]) users);
}
```

### STEP 7: Rebuild your system

```shell
sudo nixos-rebuild switch --flake .#generic-vm
```

id_ed25519 is now decrypted with sops-nix and id_ed25519.pub is auto-generated



# Troubleshooting commands for finding labels

1. `LSBLK`: This gives an overview of the discs, partitions, file systems and labels, including the Mount Points.

2. `BLKID`: This command was used to request more detailed information about the partitions and their labels.
`Sudo BLKID /DEV /VDA2`
This gives the UUID, the file system type, the label and other metadata for a specific partition.

3. `Wipefs`: This was used to erase the existing partition table and file system data of a disk or partition, which is useful to restore a clean state.
`Sudo Wipefs -a /DEV /VDA`
This deletes all inscription information (such as GPT, MBR) from the disk.

4. `Partprobe` and `udevadm trigger`: these commands were used to inform the system of changes in the disk layout, so that the kernel and device manager can recognize the new partitions.
`Sudo Partprobe /DEV /VDA`
`Sudo Udevadm Trigger-subsystem-Match = Block`
`Sudo Udevadm Settle -Timeout 120`

5. `Sgdisk`: This is used for partitioning the disk, creating the GPT partition table and setting the partition settings such as size, name, type, and so on.
`Sgdisk -Clear /DEV /VDA`
`Sgdisk-align-end--new = 1:+512M-Partition -Guid = 1: R-Chahange-Not-admitted = 1: Disk-Main-boat-TypeCode = 1: EF00 /DEV /VDA`
`Sgdisk-align-end--annew = 2: 0: -0-Partition -Guid = 2: R -Change-admission = 2: Disk-Main-Disk-Main-Boot-TypeCode = 2: 8300 /DEV /VDA`

6. `Findmnt`: This was used to check whether the partitions have been properly mounted and whether the labels are recognized correctly.
`FindMNT/DEV/Disk/by-Partlabel/Disk-Main-Disk-Main-Groot/MNT/`

7. Als je niet kan inloggen met ssh, check of de server draait `systemctl status sshd` en check of de port 22 open staat `ss -tlpn | grep :22`

8. Check firewall regels met `sudo iptables -L | grep ssh`

9. Fix backspace in VM: type `stty erase <ctrl-V> <backspace>`

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
cd ~/elixos
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


# Elixos NixOS VM Installation Workflow (SOPS)

## Flow Overview

```
+-------------------------+
|  Host Machine (Laptop)  |
+-------------------------+
          |
          |  (QEMU: ISO + VM disk)
          v
+-------------------------+
|  Live Installer (VM)    |
+-------------------------+
          |
          |  (push SOPS key & repo via SSH port 2222)
          v
+-------------------------+
|  Live Installer /tmp & /root |
+-------------------------+
          |
          |  (nixos-install → Target Disk)
          v
+-------------------------+
|  Installed NixOS system |
+-------------------------+
          |
          |  (SOPS decrypt private key to ~/.ssh/id_ed25519)
          v
+-------------------------+
|  Working SSH login keys |
+-------------------------+
```

## Full Workflow Commands

```bash
just vm_prerequisites    # Install dev tools (QEMU, SOPS, Rage)
just vm_prepare          # Prepare disk, ISO, UEFI vars
just vm_run_installer    # Boot live installer VM (localhost:2222)
just live_setup_ssh      # Start sshd on live installer
just bootstrap-vm        # Full bootstrap (key push, repo, install)
```

### bootstrap-vm does:

* push-key: scp Age key to live installer
* push-repo: push repo to /tmp/elixos.git
* clone-repo: clone repo to \~/elixos
* install-root-key: place Age key in /root/.config/sops/age
* vm\_partition: run disk layout partitioning
* vm\_install: run nixos-install

## SSH Key Encryption Workflow

```bash
just encrypt-key   # Encrypt ~/.ssh/id_ed25519 to SOPS-YAML
just show-key      # View decrypted secret
just decrypt-key   # Decrypt back to ~/.ssh/id_ed25519 (optional)
```

## Maintenance

```bash
just vm_reset         # Delete VM files & start over
just vm_build_generic-vm  # Build test VM
just vm_run           # Run installed VM
just update           # Update flake inputs
just clean            # Nix garbage collect
just fmt              # Format nix files
```

## Key Concept Recap

* Private key: `~/.config/sops/age/keys.txt`
* SOPS secrets: `nixos/secrets/generic-vm-secrets.yaml`
* On live installer: `/etc/sops/age/keys.txt` symlinked to root key
* Final decrypted SSH key: `/home/eelco/.ssh/id_ed25519`
* Repo pushed via local bare repo (no GitHub SSH needed)
