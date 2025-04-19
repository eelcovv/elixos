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

3. Test de configuratie met nixos-rebuild in een VM:

Om snel te testen of je configuratie werkt, kun je nixos-rebuild build-vm gebruiken. Dit maakt een virtuele machine met je huidige configuratie:

nixos-rebuild build-vm --flake .#new-laptop

Hiermee wordt een VM opgestart met de configuratie van de nieuwe host, die je snel kunt testen.

Snel QEMU-VM Opzetten

Voor een meer gedetailleerde test kun je een volledige QEMU-VM opzetten. Volg deze stappen om een QEMU VM te maken:

Installeren van vereiste pakketten

Installeer de benodigde QEMU-tools in je NixOS-shell:

nix-shell -p qemu-utils
nix-shell -p qemu

Maak een virtuele schijf

Maak een virtuele schijf voor de VM:

qemu-img create -f qcow2 /tmp/nixos-vm.qcow2 8G

Mount de schijf

Mount de schijf zodat je toegang hebt tot het bestandssysteem:

sudo mount /tmp/nixos-vm.qcow2 /tmp/nixos-vm

Maak de benodigde directories en clone de repository

Maak de etc directory en clone je repository:

mkdir /tmp/nixos-vm/etc
cd /tmp/nixos-vm/etc
git clone git@github.com:eelcovv/eelco-nixos.git nixos
cd /tmp/nixos-vm/etc

Start de QEMU-VM

Start de VM met de NixOS ISO en koppel de virtuele schijf:

qemu-system-x86_64 -m 4096 -smp 2 -boot d -cdrom /tmp/nixos-vm.iso/nixos-minimal-24.11.716947.26d499fc9f1d-x86_64-linux.iso -drive file=/tmp/nixos-vm.qcow2,format=qcow2 -display gtk -net user,hostfwd=tcp::2222-:22 -net nic

SSH Inloggen

Na het opstarten kun je inloggen op de VM via SSH. Als je hostfwd=tcp::2222-:22 hebt ingesteld, kun je inloggen met:

ssh -p 2222 root@localhost

Configureer en Test

Je kunt nu de configuratie testen door bijvoorbeeld nixos-rebuild switch uit te voeren binnen de VM om je nieuwe instellingen toe te passen.

Meer informatie

- NixOS Manual (https://nixos.org/manual/)
- NixOS Flakes (https://nixos.wiki/wiki/Flakes)


