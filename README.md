
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
nix-shell -p qemu qemu-utils OVMF just
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

Download eerst de iso

```shell
curl -o $HOME/vms/nixos-minimal.iso -L https://channels.nixos.org/nixos-24.11/latest-nixos-minimal-x86_64-linux.iso
```

Ook gaan we de  Open Virtual Machine Firmware gebruiken. Hiervoor hadden we al OVFM geinstalleerd. Zoek de benodigde bestanden op:

```shell
nix-build '<nixpkgs>' -A OVMF.fd
```

Dit geeft een locatie als `/nix/store/kw52jax4fh89aj4gnk6pclwixagcsdjr-OVMF-202411-fd`

JE moet nu de bestanden kopieren. Dit kan gelijk met

```shell
sudo cp -v $(nix-build '<nixpkgs>' -A OVMF.fd)/FV/OVMF_CODE.fd $HOME/vms/
```

Nu staat de OVMF_CODE.fd in je eigen vms directory

Nu moet onze uefi_vars.fd verwijzen naar de OVMF_vars.fd, dus copieer ook

```shell
sudo cp -v $(nix-build '<nixpkgs>' -A OVMF.fd)/FV/OVMF_VARS.fd $HOME/vms/uefi_vars.fd
```



Start de VM met de NixOS ISO en koppel de virtuele schijf:

```shell
qemu-system-x86_64 \
  -enable-kvm \
  -m 16384 \
  -drive if=pflash,format=raw,readonly=on,file=$HOME/vms/OVMF_CODE.fd \
  -drive if=pflash,format=raw,file=$HOME/vms/uefi_vars.fd \
  -drive if=virtio,file=$HOME/vms/nixos-vm.qcow2,format=qcow2 \
  -nic user,model=virtio-net-pci,hostfwd=tcp::2222-:22
```

Dit is gelijk aan het opstarten van een nixos live-usb.

Na het opstarten verander je het password in de qemu terminal met:

```shell
passwd
```

6. Installeren van NixOS

Zodra de QEMU-VM is opgestart, kun je inloggen en de installatie uitvoeren. Stel een wachtwoord in:

```shell
ssh -p 2222 nixos@localhost
```

Mocht je je qemu vm meerdere keren opstarten dan krijg je de fingerprint warning als je weer met ssh naar de local machine in wilt loggen. Om deze schoon te maken kan je runnen

```shell
ssh-keygen -R "[localhost]:2222"
```

Als je ingelogd ben maak je een ssh key aan met

Clone vervolgens je repository en configureer de schijf:
```shell
ssh-keygen
```

```shell
git clone git@github.com:eelcovv/eelco-nixos.git
```

En ga in je repo met
```shell
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
sudo nixos-install --flake .#tongfang-vm
```

9. Sluit de VM en Herstart

Sluit de QEMU-VM die de live ISO draait. Je kunt de VM opnieuw opstarten met:

```shell
qemu-system-x86_64 \
  -enable-kvm \
  -m 16384 \
  -drive if=pflash,format=raw,readonly=on,file=$HOME/vms/OVMF_CODE.fd \
  -drive if=pflash,format=raw,file=$HOME/vms/uefi_vars.fd \
  -drive if=virtio,file=$HOME/vms/nixos-vm.qcow2,format=qcow2 \
  -nic user,model=virtio-net-pci,hostfwd=tcp::2222-:22
```

10. Herbouw de Boot Systeem (eventueel als je wat veranderd hebt)

Voer een rebuild van het boot-systeem uit:

```shell
sudo nixos-rebuild boot --flake .#tongfang-vm
```