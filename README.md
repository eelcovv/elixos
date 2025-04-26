
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

Voor een meer gedetailleerde test kun je een volledige QEMU-VM opzetten. 

Als eerst een globaal overzicht. We gaan het volgende doen:

:

🧩 1. Setup in de live-omgeving (via SSH)
1. Je logt in op de VM met SSH.

2. Je maakt een SSH-key aan en voegt deze toe aan je GitHub-account.

3. Je clone’t je eelco-nixos repository naar ~/eelco-nixos.

💾 2. Diskopzet met disko
```shell
sudo nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko -- --mode zap_create_mount ./nixos/disks/qemu-vm.nix
```

* --mode zap_create_mount wist de schijf, creëert de partities, en mount alles op de juiste plekken voor nixos-install.

* Disko gebruikt jouw config (qemu-vm.nix) om de schijf te partitioneren (waarschijnlijk met LUKS en/of LVM?).

🧱 3. Installatie van NixOS
```shell
sudo nixos-install --flake .#tongfang-vm
```
* Installatie vanuit jouw flake, met tongfang-vm als hostname/system.

* Ervan uitgaande dat je nixosConfigurations.tongfang-vm correct hebt gedefinieerd in flake.nix.

🔁 4. Herstart in QEMU met UEFI + forwarding
```shell
qemu-system-x86_64 \
  -enable-kvm \
  -m 16384 \
  -drive if=pflash,format=raw,readonly=on,file=$HOME/vms/OVMF_CODE.fd \
  -drive if=pflash,format=raw,file=$HOME/vms/uefi_vars.fd \
  -drive if=virtio,file=$HOME/vms/nixos-vm.qcow2,format=qcow2 \
  -nic user,model=virtio-net-pci,hostfwd=tcp::2222-:22
```
Uiteindelijke setup: met UEFI (OVMF), KVM-acceleration, virtio, en poort-forwarding voor SSH (poort 2222 lokaal → 22 in de VM).

Hierna zou je kunnen inloggen met:
```shell
ssh -p 2222 eelco@localhost
```


Volg deze stappen om een QEMU VM te maken:

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


## Troubleshooting Commando's voor het Vinden van Labels

1. `lsblk`: Dit geeft een overzicht van de schijven, partities, bestandssystemen en labels, inclusief de mount points.

2. `blkid`: Dit commando werd gebruikt om gedetailleerdere informatie over de partities en hun labels op te vragen.
   `sudo blkid /dev/vda2`
   Dit geeft de UUID, het bestandssysteemtype, de label en andere metadata voor een specifieke partitie.

3. `wipefs`: Dit werd gebruikt om de bestaande partitietabel en bestandssysteemgegevens van een schijf of partitie te wissen, wat handig is om een schone staat te herstellen.
   `sudo wipefs -a /dev/vda`
   Hiermee wordt alle opschriftinformatie (zoals GPT, MBR) van de schijf gewist.

4. `partprobe` en `udevadm trigger`: Deze commando's werden gebruikt om het systeem op de hoogte te stellen van veranderingen in de schijfindeling, zodat de kernel en device manager de nieuwe partities kunnen herkennen.
   `sudo partprobe /dev/vda`
   `sudo udevadm trigger --subsystem-match=block`
   `sudo udevadm settle --timeout 120`

5. `sgdisk`: Dit is gebruikt voor het partitioneren van de schijf, het creëren van de GPT-partitietabel en het instellen van de partitie-instellingen zoals grootte, naam, type, enzovoorts.
   `sgdisk --clear /dev/vda`
   `sgdisk --align-end --new=1:0:+512M --partition-guid=1:R --change-name=1:disk-main-boot --typecode=1:EF00 /dev/vda`
   `sgdisk --align-end --new=2:0:-0 --partition-guid=2:R --change-name=2:disk-main-disk-main-root --typecode=2:8300 /dev/vda`

6. `findmnt`: Dit werd gebruikt om te controleren of de partities goed zijn gemount en of de labels correct herkend worden.
   `findmnt /dev/disk/by-partlabel/disk-main-disk-main-root /mnt/`

Door deze stappen zorgvuldig uit te voeren, kon je zowel de partitionering als de labels goed configureren.

# Workflow NixOS ontwikkelen en testen via tongfang-vm

## 1. Aanpassen op Tongfang (hoofd-laptop)

- Pas je configuratie aan (bijv. `nixos/hosts/tongfang-vm.nix`)
- Commit en push naar GitHub:

```shell
git add .
git commit -m "korte omschrijving"
git push
```

## 2. Updaten en rebuilden op tongfang-vm

* SSH naar je VM (of open terminal in de VM)
* Haal laatste wijzigingen op en rebuild:


```shell
cd ~/eelco-nixos
git pull
sudo nixos-rebuild switch --flake .#tongfang
```

## 3. Testen
 * Controleer of je wijziging werkt zoals bedoeld.
 * Indien nodig rollback:

```shell
sudo nixos-rebuild switch --rollback
```

## 4. Als alles werkt

Pas daarna dezelfde push-pull-rebuild stap toe op je echte Tongfang laptop.

## Extra tips

* Gebruik sudo nixos-rebuild test --flake .#tongfang als je tijdelijk iets wil proberen zonder direct te activeren.

* Maak snapshots van je VM voor grote wijzigingen.

* Houd SSH open op tongfang-vm zodat je makkelijker kunt deployen.