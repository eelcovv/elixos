# Eelco's Nixos configuration

##  Reminders 

### Creating a hardware configuration:

de hardware configuratie wordt gemaakt met:


handmatig formatteren als je nog geen installatie hebt:

```shell
nix-shell -p nixpkgs-fmt --run "nixpkgs-fmt ."
```


``` shell
nix
```

Testen configuratie:

```shell
nixos-rebuild build-vm --flake .#tongfang
```


Install  qemu in een shell

``` shell
nix-shell -p qemu-utils.out
nix-shell -p qemu
```

en ook 

maak een virtuele schijf:

``` shell
qemu-img create -f qcow2 /tmp/nixos-vm.qcow2 8G
```

mount de schijf
``` shell
sudo mount  /tmp/nixos-vm.qcow2 /tmp/nixos-vm
```
maak een etc directory en ga er naar to

``` shell
mkdir /tmp/nixos-vm/etc
cd /tmp/nixos-vm/etc
```

clone de repository

``` shell
git clone git@github.com:eelcovv/eelco-nixos.git nixos
cd /tmp/nixos-vm/etc
```

``` shell
qemu-system-x86_64 -m 4096 -smp 2 -boot d -cdrom /tmp/nixos-vm.iso/nixos-minimal-24.11.716947.26d499fc9f1d-x86_64-linux.iso -drive file=/tmp/nixos-vm.qcow2,format=qcow2 -display gtk -net user,hostfwd=tcp::2222-:22 -net nic
```