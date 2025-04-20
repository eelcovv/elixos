# Eelco's NixOS Configuration

## Introductie

Dit project bevat de configuratie voor mijn NixOS-setup. Het is opgebouwd om een **multi-user**, **multi-host** systeem te ondersteunen, wat betekent dat je gemakkelijk verschillende gebruikers en systemen kunt configureren. De configuratie is modulair en maakt gebruik van een **flake** voor het beheer van NixOS-installaties. Dit zorgt voor herbruikbaarheid en overzichtelijkheid bij het beheren van verschillende hosts en gebruikers.

## Projectstructuur

De configuratie is opgedeeld in de volgende directories:
- **`modules/`**: Bevat alle configuratie-modules die herbruikbaar zijn voor verschillende systemen.
  - **`common.nix`**: Bevat instellingen die op alle systemen van toepassing zijn, zoals gebruikersbeheer, netwerkconfiguratie, en meer.
- **`hosts/`**: Bevat configuraties voor specifieke systemen, zoals laptops, servers, etc.
- **`users/`**: Bevat configuraties voor verschillende gebruikers, zodat je eenvoudig gebruikers kunt hergebruiken op verschillende hosts.
- **`hardware/`**: Bevat hardware-specifieke configuraties zoals partities en LUKS-encryptie.

## Toevoegen van een nieuwe host

Om een nieuwe host toe te voegen, kun je de volgende stappen volgen:

1. **Genereer de hardwareconfiguratie voor de nieuwe host:**

   Gebruik het `nixos-generate`-commando om een hardwareconfiguratie te maken voor de nieuwe machine:
   
   ```shell
   nixos-generate -c config
   ```

   Dit zal een bestand hardware-configuration.nix genereren dat je kunt gebruiken voor je nieuwe host.

2. Maak een nieuwe hostconfiguratie in de hosts/ directory:

Maak een nieuwe .nix-file aan in de hosts/ directory en configureer de nodige instellingen voor de nieuwe machine. Bijvoorbeeld voor een nieuwe laptop:

# hosts/new-laptop.nix
```text
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

3. Test de configuratie met nixos-rebuild in een VM:

Om snel te testen of je configuratie werkt, kun je nixos-rebuild build-vm gebruiken. Dit maakt een virtuele machine met je huidige configuratie:

```shell
nixos-rebuild build-vm --flake .#new-laptop
```

Hiermee wordt een VM opgestart met de configuratie van de nieuwe host, die je snel kunt testen.

Snel QEMU-VM Opzetten

Voor een meer gedetailleerde test kun je een volledige QEMU-VM opzetten. Volg deze stappen om een QEMU VM te maken:

## Installeren van vereiste pakketten

Installeer de benodigde QEMU-tools in je NixOS-shell:

```shell
nix-shell -p qemu-utils
nix-shell -p qemu
```

## Maak een virtuele schijf

Maak een virtuele schijf voor de VM:

```shell
qemu-img create -f qcow2 /tmp/nixos-vm.qcow2 8G
```

## Mount de schijf

Mount de schijf zodat je toegang hebt tot het bestandssysteem:

```shell
sudo mount /tmp/nixos-vm.qcow2 /tmp/nixos-vm
```

## Maak de benodigde directories en clone de repository

Maak de etc directory en clone je repository:


```shell
mkdir /tmp/nixos-vm/etc
cd /tmp/nixos-vm/etc
git clone git@github.com:eelcovv/eelco-nixos.git nixos
cd /tmp/nixos-vm/etc
```

Dit clonen kan ook later als je je vm opstart in live-usb mode. 

## Start de QEMU-VM

Start de VM met de NixOS ISO en koppel de virtuele schijf:

```shell
qemu-system-x86_64 -m 4096 -smp 2 -boot d \
  -cdrom /tmp/nixos-vm.iso/nixos-minimal-24.11.716947.26d499fc9f1d-x86_64-linux.iso \
  -drive if=virtio,file=/tmp/nixos-vm.qcow2,format=qcow2 \
  -display gtk -net user,hostfwd=tcp::2222-:22 -net nic
```

Je hebt nu een qemo geopend also je in feite nixos in een live-usb mode draait. Je wilt nu een installatie van deze live-usb op je virtuele harde schijf maken.
Let op, de optie virtio zorgt ervoor dat je harde schijven vda heten ipv sda. Dit is duidelijker voor als je in een vm werkt en ook sneller.


## SSH Inloggen

Na het opstarten kun je inloggen op de VM via SSH. Als je hostfwd=tcp::2222-:22 hebt ingesteld, kun je inloggen met:

```shell
ssh -p 2222 root@localhost
```

Je kan nu in deze terminal je repo clonen zodat je met je configuratie verder kan gaan. Maak even een ssh key aan, voeg deze aan je git hub toe en clone je repo:

Mocht je je qemu vm meerdere keren opstarten dan krijg je de fingerprint warning als je weer met ssh naar de local machine in wilt loggen. Om deze schoon te maken kan je runnen

```shell
ssh-keygen -R "[localhost]:2222"
```

```shell
ssh-keygen
```

en de inhoud van ~/.ssh/id_ed25519.pub toevoegen aan je keys. 

Nu clone je de repo nu naar je home. Doe dit als nixos user want daarmee heb je de ssh-keys gemaakt

```shell
git clone git@github.com:eelcovv/eelco-nixos.git 
```

en verhuis het nu naar je /mnt

```shell
sudo mv eelco-nixos /mnt
```


Nu heb je de virtuele vm harde schijf nog niet gepartitioneerd en gemount, maar dat wordt met dit commando gedaan

```shell
sudo nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko -- --mode zap_create_mount /mnt/eelco-nixos/nixos/disks/qemu-vm.nix
```

Als het goed is, is /mnt nu weer leeg met alleen /mnt/boot. Je moet je eelco-nixos weer opnieuw clonen en naar de /mnt moven. Je kunt nu runnen

```shell
sudo nixos-install --flake /mnt/eelco-nixos#tongfang-vm
```
