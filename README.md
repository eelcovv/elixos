
# Eelco's NixOS Configuratie

## Introductie

Dit project bevat de configuratie voor mijn NixOS-setup. Het is ontworpen om een **multi-user**, **multi-host** systeem te ondersteunen, wat betekent dat je eenvoudig verschillende gebruikers en systemen kunt configureren. De configuratie is modulair en maakt gebruik van een **flake** voor het beheer van NixOS-installaties, wat zorgt voor herbruikbaarheid en overzichtelijkheid bij het beheren van verschillende hosts en gebruikers.

## Projectstructuur

De configuratie is opgedeeld in de volgende directories:
- **`modules/`**: Bevat alle configuratie-modules die herbruikbaar zijn voor verschillende systemen.
  - **`common.nix`**: Bevat instellingen die op alle systemen van toepassing zijn, zoals gebruikersbeheer, netwerkconfiguratie, en meer.
- **`hosts/`**: Bevat configuraties voor specifieke systemen, zoals laptops, servers, etc.
- **`users/`**: Bevat configuraties voor verschillende gebruikers, zodat je eenvoudig gebruikers kunt hergebruiken op verschillende hosts.
- **`hardware/`**: Bevat hardware-specifieke configuraties zoals partities en LUKS-encryptie.

## Toevoegen van een Nieuwe Host

Om een nieuwe host toe te voegen, kun je de volgende stappen volgen:

### 1. Genereer de Hardwareconfiguratie voor de Nieuwe Host

Gebruik het `nixos-generate`-commando om een hardwareconfiguratie te maken voor de nieuwe machine:

```shell
nixos-generate -c config
```

Dit genereert een bestand `hardware-configuration.nix` dat je kunt gebruiken voor je nieuwe host.

### 2. Maak een Nieuwe Hostconfiguratie in de `hosts/` Directory

Maak een nieuwe `.nix`-file aan in de `hosts/` directory en configureer de benodigde instellingen voor de nieuwe machine. Bijvoorbeeld, voor een nieuwe laptop:

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

### 3. Test de Configuratie met `nixos-rebuild` in een VM

Om snel te testen of je configuratie werkt, kun je `nixos-rebuild build-vm` gebruiken. Dit maakt een virtuele machine met je huidige configuratie:

```shell
nixos-rebuild build-vm --flake .#new-laptop
```
Hiermee wordt een VM opgestart met de configuratie van de nieuwe host, die je snel kunt testen.

## QEMU-VM Opzetten

Voor een meer gedetailleerde test kun je een volledige QEMU-VM opzetten. Volg deze stappen om een QEMU VM te maken:

1. Installeer de Vereiste Pakketten

Installeer de benodigde QEMU-tools in je NixOS-shell:

```shell
nix-shell -p qemu-utils
nix-shell -p qemu
```

2. Maak een Virtuele Schijf

Maak een virtuele schijf voor de VM:

```shell
qemu-img create -f qcow2 $HOME/vms/nixos-vm.qcow2 30G
```

Om later de schijf te vergroten, gebruik je:

``` shell
qemu-img resize $HOME/vms/nixos-vm.qcow2 +20G
```

3. Mount de Schijf

Mount de schijf zodat je toegang hebt tot het bestandssysteem:

```shell
sudo mount $HOME/vms/nixos-vm.qcow2 $HOME/vms/nixos-vm
```

4. Maak de Benodigde Directories en Clone de Repository

Maak de etc/ directory aan en clone je repository:

```shell
mkdir $HOME/vms/nixos-vm/etc
cd $HOME/vms/nixos-vm/etc
git clone git@github.com:eelcovv/eelco-nixos.git nixos
cd $HOME/vms/nixos-vm/etc
```

Dit clonen kan ook later wanneer je de VM opstart in live-USB-modus.

5. Installeer de iso QEMU-VM

Let op: dit wist de inhoud van je virtuele harde schijf en begint met een nieuwe installatie.

Start de VM met de NixOS ISO en koppel de virtuele schijf:

```shell
qemu-system-x86_64 -m 4096 -smp 2 -boot d \
  -cdrom $HOME/vms/nixos-vm.iso/nixos-minimal-24.11.716947.26d499fc9f1d-x86_64-linux.iso \
  -drive if=virtio,file=$HOME/vms/nixos-vm.qcow2,format=qcow2 \
  -display gtk -net user,hostfwd=tcp::2222-:22 -net nic
  ```

6. Installeren van NixOS

Zodra de QEMU-VM is opgestart, kun je inloggen en de installatie uitvoeren. Stel een wachtwoord in:

```shell
passwd
```

Clone vervolgens je repository en configureer de schijf:

```
git clone git@github.com:eelcovv/eelco-nixos.git
cd eelco-nixos
```

7. Partitioneer en Mount de Schijf

Gebruik disko om de schijf te partitioneren en te mounten:

```shell
sudo nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko -- --mode zap_create_mount ./nixos/disks/qemu-vm.nix
```

8. Voer de NixOS Installatie Uit

Voer de installatie uit met:

```shell
sudo nixos-install --flake /mnt/eelco-nixos#new-laptop
```

9. Herbouw de Boot Systeem

Voer een rebuild van het boot-systeem uit:

```shell
sudo nixos-rebuild boot --flake /mnt/eelco-nixos#new-laptop
```

10. Sluit de VM en Herstart

Sluit de QEMU-VM die de live ISO draait. Je kunt de VM opnieuw opstarten met:

```shell
qemu-system-x86_64   -enable-kvm   -m 16384   -drive file=$HOME/vms/nixos-vm.qcow2,format=qcow2   -boot order=c   -nic user,model=virtio-net-pci
```