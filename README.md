<!-- markdownlint-disable-next-line MD041 -->
<p align="center">
  <img src="logo.png" alt="elixos logo" width="200"/>
</p>

# elixos

<!-- markdownlint-disable-next-line MD036 -->
_The Declarative Cure for Your NixOS Headaches_

## 🌐 Introduction

**Elixos** is a modular, declarative NixOS configuration system for multi-host and multi-user environments.  
It leverages flakes and sops-nix for secure, reproducible, and extendable NixOS installations.

## 📁 Project Structure

The elixos structure looks like:

elixos
├── home
│   ├── modules
│   │   ├── benchmarking
│   │   ├── common
│   │   ├── databases
│   │   ├── desktop
│   │   ├── development
│   │   ├── editors
│   │   ├── engingeering
│   │   ├── graphics
│   │   ├── hyperland
│   │   ├── internet
│   │   ├── maintainance
│   │   ├── multimedia
│   │   ├── office
│   │   ├── publishing
│   │   ├── security
│   │   ├── shells
│   │   ├── socialmedia
│   │   └── terminals
│   └── users
├── nixos
│   ├── disks
│   ├── hardware
│   │   ├── alloy
│   │   ├── contabo
│   │   ├── singer
│   │   └── tongfang
│   ├── hosts
│   ├── modules
│   │   ├── disk-layouts
│   │   ├── fonts
│   │   ├── hardware
│   │   ├── lib
│   │   ├── profiles
│   │   ├── secrets
│   │   └── services
│   ├── secrets
│   │   └── surfshark
│   └── users
└── scripts
    ├── bootstrap
    ├── install
    └── vpn

This installs all the required development tools.

Use the following steps to quickly install a NixOS VM using QEMU.

## 🔑 Initial Setup: Generating Your Age Key

Before you can encrypt secrets for your NixOS hosts using `sops-nix`, you must first generate a master
Age key **once** on your main (host) machine.

### Step 1: Generate your master Age key

Run the following command on your host system:

```shell
mkdir -p ~/.config/sops/age
rage-keygen -o ~/.config/sops/age/keys.txt
```

This creates a private key in `~/.config/sops/age/keys.txt`. Make sure this file is **never shared** and
backed up securely (e.g. to an encrypted external drive or secure password manager).

### Step 2: View the public key

To view and copy the corresponding public key:

```shell
rage-keygen -y ~/.config/sops/age/keys.txt
```

Use this public key whenever encrypting secrets for any target system
(VM, laptop, etc.).

## 🚀 Quick VM Installation Workflow

### 🛠️ 1. Preparation on the Host

```shell
just vm_prerequisites      # Install qemu, ovmf, rage, sops
just vm_reset              # Remove old VM files
just vm_prepare            # Download ISO and create VM disk
just vm_run_installer      # Boot the live installer in QEMU
```

In the newly started Qemu window, login as root with

```shell
sudo su
```

and set a password for the root with

```shell
passwd
```

Just pick an easy password like _nixos_, as it is temporarly used anyway.

At this point, you should be able to login on the Live Installer by accessing the localhost on port 2222.
In the next steps, we are going to use that.

### 🔐 2. Bootstrap the VM from the Host

Now your Live installer has started, open an new terminal in your local machine and run just
vm_prerequisites again to load the needed application. In this new terminal, load the .env file which
set the environment variables of the current setup. For instance, load:

```shell
. .env-generic-vm
```

This sets:

```text
HOST=generic-vm
SSH_USER=root
SSH_PORT=2222
SSH_HOST=localhost
REPO_DIR=/root/elixos
```

Now you can run the bootstrap for this VM

```shell
just bootstrap-vm
```

This performs the following:

- Pushes your Age master key (keys.txt) to the live installer
- Pushes your repo to a bare Git repo on the VM
- Clones the repo into ~/elixos on the VM
- Installs the master key to /etc/sops/age/keys.txt
- Partitions the disk using disko
- Installs NixOS using the `generic-vm` configuration

### ▶️ 3. Boot the Installed VM

First, close the live installer and start up your newly create VM with:

```shell
just vm_run
```

After bootstrapping the VM, the age key is available in memory, but not yet in the installed system.
To fix that, after booting the VM, first load you new environment of the new virtual machine you have just installed.
First you have to close the still running Live installer. Then do:

```shell
. .env.localhost
```

This sets

```text
HOST=generic-vm
SSH_USER=eelco
SSH_HOST=localhost
SSH_PORT=2222
REPO_DIR=/home/eelco/elixos
```

Now you can run:

```shell
just post-boot-setup generic-vm eelco
```

This will:

- Push the age key to the real VM
- Install the key to /etc/sops/age/keys.txt
- Push and clone the repo again
- Prepare for `nixos-rebuild switch`

At this point you can start your newly created VM. Make sure to close the Live
Installer first, because you cannot run two QEMU windows simultaneously.
Then, start the VM with:

### 🔑 4. SSH Login

    ssh -p 2222 eelco@localhost

If backspace does not work:

    export TERM=xterm

## 🧪 Development & Testing via VM

1. Modify your configuration (e.g. `hosts/tongfang.nix`, `modules/`, etc.)
2. Push to GitHub or directly to the live VM:

   ```shell
   git add . && git commit -m "Update" && git push
   ```

3. On the VM:

   ```shell
   cd ~/elixos
   git pull
   sudo nixos-rebuild switch --flake .#generic-vm
   ```

   The last command can be replaced with

   ```shell
   just switch generic-vm
   ```

   Try restarting your machine if you dont see an id_ed25519 file yet in your .ssh folder

## 🔐 SOPS and SSH Key Management

Secrets like your SSH private key are stored as encrypted YAML files.

### 🔑 Create and Encrypt a New Key

```shell
    just make-secret HOST USER
```

This creates:

- `~/.ssh/ssh_key_HOST_USER`
- `nixos/secrets/HOST-USER-secrets.yaml`

### 📦 Encryption Helpers

```shell
just encrypt-key       # Convert ~/.ssh/id_ed25519 to encrypted YAML
just show-key          # View decrypted secret
just decrypt-key       # Restore ~/.ssh/id_ed25519 from secrets
```

## 🔧 Maintenance

```shell
just update              # Update flake inputs
just clean               # Run nix garbage collection
just fmt                 # Format all .nix files
just vm_reset            # Reset and clean VM setup
just vm_build_generic-vm # Build the system only (no run)
```

## 🧩 Live Installer SSH Setup

For manual access to the live installer:

```shell
just live_setup_ssh       # Start sshd and set root password
just ssh_authorize USER   # Add your SSH key to the live VM
```

## 📈 Installation Flow Visualization

```text
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
```

### 📚 Tips

- Add `export TERM=xterm` to your VM shell profile for better terminal compatibility.
- Use `just vm_run_gpu` for graphical output with virtio-vga and virgl.
- Create VM snapshots before major system changes.

Happy hacking with Elixos! 🧬

## Steps laptop installation

### Preparation

1. Download the [https://nixos.org/download/](nixos minimal ISO image) and create a live USB starter with it

2. Start up live NIXOS installer

   Tip: use the copytoram option to prevent issues during startup (blackscreen)

### Connectig with wifi

#### Method 1: using ip/iw and wpa_passphrase

1. **Log in as root**

   ```shell
   sudo su
   ```

2. **Look up the name of your wifi device**

   ```shell
   ip link
   ```

   The name is for example `wlp2s0`

3. **Scan the available networks**

   ```shell
   iw dev wlp2s0 scan | grep SSID
   ```

   If you get: 'Network is down (-100), activate it with:

   ```shell
   ip link set wlp2s0 up
   ```

   If you now get `Operation not possible due to RF-kill`, then check

   ```shell
   rfkill list
   ```

   Check if

   ```shell
   0: phy0: Wireless LAN
       Soft blocked: yes
       Hard blocked: no
   ```

   If it it soft blocked, unblock with

   ```shell
   rfkill unblock all
   ```

   Now, activate your device

   ```shell
   ip link set wlp2s0 up
   ```

   and scan again

   ```shell
   iw dev wlp2s0 scan | grep SSID
   ```

   Also, check if you on the right interface with:

   ```shell
   iw dev
   ```

   this should show:

   ```shell
   Interface wlp2s0
   type: managed
   ```

   Now you should see your network

4. **Connect to your network**

```shell
wpa_passphrase "mijn-wifi-ssid" "mijn-wifi-wachtwoord" > wpa.conf
```

and then

```shell
wpa_supplicant -B -i wlp2s0 -c wpa.conf
```

and now request a ip-address using

```shell
dhcpcd wlp2s0
```

You can ignore the notification `read_config: /etc/dhcpcd.conf: No such file or directory`.
Just check that you are connected with:

```shell
ip a show wlp2s0
```

Also, check if you are connected to the internet with

```shell
ping 1.1.1.1
```

#### Method 2: using nmtui

Just start:

```shell
nmtui
```

And set you password to the network in the terminal interface.

### Starting sshd deamon

To start your demeaon, first set your root password with

```shell
passwd
```

Then run

```shell
sudo systemctl start sshd
```

Check if it is running

```shell
sudo systemctl status sshd
```

Look up your ip address with:

```shell
ip ad
```

It should be something like `192.168.2.3`

### Loging in on the live installer from a host laptop

Make sure you have set the _root_ password. To do that, on your live installer, login as root as

```shell
sudo su
```

and

```shell
passwd
```

Then you should be able to login from your host machine as

```shell
ssh root@192.168.2.3
```

If you get a warning about 'Remote Host Identification Has Changed', you have probably logged in on
this IP Address earlier. Delete you key with

```shell
ssh-keygen -R "[192.168.2.3]:22"
```

Alternatively, you can just open your `~/.ssh/known_hosts` file and look for the lines containing
`192.168.2.3` and remove those lines.

#### trouble shooting for logging in

In case logging in is not allowed at all, you may want to change your _/etc/ssh/sshd_config_ file.
Since in nixos you cannot change settings files (even not as root), just copy the file to your home

```shell
cp /etc/ssh/sshd_config ~
```

You may want to change the setting _UsePAM Yes_ to _UsePAM No_

Then, restart your sshd deamon with this new settings file as

```shell
sudo $(which sshd) -f ~/sshd_config
```

Note that this which sshd is needed since you need to use the full path to the sshd file.

Check if you are now listening to port 22 with

```shell
ss -tlnp | grep 22
```

```shell
sudo useradd -r -s /urs/sbin/nologin -c "sshd user" sshd
```

start sshd in the background with

```shell
sudo nix run --extra-experimental-features 'nix-command flakes' github:nix-community/disko -- \
            --flake .#singer --mode zap_create_mount
```

to login: don't use password, but copy you public ssh key and add to authorized_keys.
I used keep to copy my key.

Also check your firewall if it is not running

To transer your git repo, either bundle or just add your publish key to your git hub account

### Transfering the installation reoo to your laptop

From now on, you can use the justfile entries to install the laptop

First, load the laptop environment

```shell
. ./.env.singer
```

and run

```shell
just bootstrap-laptop singer
```

This performs all the steps. After you are done, reboot your laptop and login via ssh again and then do

```shell
just post-boot-setup singer eelco
```

This installs the age key back to /etc/sops/age

Now, on the new target in de elixos repo, run

```shell
just switch singer
```

This should finalize your installation

### Tranfering you git repository to the laptop

In your terminal where you are remotely logged in on you laptop do:

```shell
mkdir /tmp/elixos.git
```

and turn it into a bare repository with

```shell
git init --bare /tmp/elixos.git
```

On you host, do

```shell
ssh-copy-ip root@192.168.2.3
```

to prevent that you have to type a password each time

In your elixos repository do

```shell
git remote add nixtmp root@192.168.2.3:/tmp/elixos.git
```

No you can push your repository to the laptop with

```shell
git push nixtmp main
```

### Installing your laptop

Install just to be able to use is

```shell
nix-shell -p just
```

Start with running disko to partition your hard-drive

```shell
just partition singer
```

Check your partitions with

```shell
findmnt /mnt
```

which should give you

```text
TARGET
        SOURCE         FSTYPE OPTIONS
/mnt /dev/nvme0n1p2 ext4   rw,relatime
```

Copy the sops age key to the laptop installer. Run from your host:

```shell
scp ~/.config/sops/age/keys.txt root@192.168.2.3:~
```

And then run in your live installer

```shell
mkdir /root/.config/sops
```

```shell
mv /root/keys.txt /root/.config/sops
```

And also copy them to your future hardrive

```shell
mkdir -p /mnt/etc/sops/age
cp /root/keys.txt /mnt/etc/sops/age/keys.txt
chmod 400 /mnt/etc/sops/age/keys.txt
```

⚠️ Important: `hardware-configuration.nix` can only be generated after the partitions have been created and mounted.

To initialize the disk layout:

    sudo nix run github:nix-community/disko -- --flake .#tongfang --mode zap_create_mount

Then generate the hardware configuration:

    sudo nixos-generate-config --root /mnt

After that, copy the generated `hardware-configuration.nix` to:

    nixos/hardware/tongfang/hardware-configuration.nix

You can then proceed with `nixos-rebuild` or `nixos-install` using your flake-based configuration.

Now you can install your laptop with

```shell
nixos-install --flake .#singer
```

After installing, if you ssh keys are not present yet, you can try the following.

First, loging onto your newly installed laptop using the same prodceedure as above (start sshd deamon).
Then copy the `~/.config/sops/age/keys.txt` file to the newly installed laptop.
Clone the repository to the newly installed laptop. Then do this:

```shell
mkdir -p /mnt/etc/sops/age
cp /root/keys.txt /mnt/etc/sops/age/keys.txt
chmod 400 /mnt/etc/sops/age/keys.txt
```

And try to rebuild your system with

```shell
sudo nixos-rebuild switch --flake .#singer
```

## 💽 Elixos Server Installation Guide (Contabo Example)

This guide describes how to install the **Elixos** operating system on a remote server. The example below assumes a **Contabo server**, but the process works for **any x86\_64 Linux machine in rescue mode or with Ubuntu pre-installed**.

---

### 🚧 1. Boot into Rescue Mode or Install Ubuntu

1. Install **Ubuntu LTS 22.04** (or later) on your server with a root user.
2. SSH into the machine using the SSH key you provided during setup.

---

### 🧪 2. Install Nix

First, install required packages:

```sh
apt update && apt install -y xz-utils git
```

Install [`just`](https://github.com/casey/just):

```sh
snap install just --classic
```

---

### 📦 3. Set Up Your Host Environment

On your **local machine (not the server)**, source the environment file:

```sh
. ./.env.contabo
```

This sets the following environment variables:

```sh
export HOST=contabo
export SSH_USER=root
export SSH_PORT=22
export SSH_HOST=194.146.13.222
export REPO_DIR=/tmp/elixos
```

Make sure `SSH_HOST` points to the **public IP of your server**.

---

### 🚀 4. Bootstrap and Install Elixos

From your **local machine**, run:

```sh
just bootstrap-base
```

This clones the Elixos repository to the remote server.

Then SSH into the server:

```sh
ssh root@$SSH_HOST
cd /root/elixos
```

Now run the following steps to install Elixos:

```sh
just install_nix_installer_on_ubuntu
just build_on_ubuntu contabo
just install_on_ubuntu contabo
```

Alternatively, you can do everything in one go:

```sh
just install_server contabo
```

---

### 🔁 5. Reboot and Finalize

After installation, **reboot the server** into your new NixOS system.

Once it boots, run the following to re-clone your repository (if needed):

```sh
just bootstrap-base
```

Then log in again and go to the cloned repo:

```sh
cd ~/elixos
```

Finalize the configuration:

```sh
just switch contabo
```

You're done! 🎉

## VPN instructions 

Here some instructions to activate a VPN if you have one available. The instructions are based on surfshark.

### Create a VPB private/public key pair

To anounce your self at the vpn provide, you can create a key pair doing:

```sh
just gen-surfshare-wg
```


