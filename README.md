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
