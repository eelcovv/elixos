# ========== DEFAULT CONFIGURATION ========== 
HOST := env("HOST", "localhost")
INSTALL_USER := env("INSTALL_USER", "root")
POST_USER := env("USER", "eelco")
SSH_USER := env("SSH_USER", "root")
SSH_PORT := env("SSH_PORT", "22")
SSH_HOST := env("SSH_HOST", "localhost")

REPO_DIR := "~/elixos"

# ========== GENERAL ==========
default:
	just --list --unsorted

# ========== HOST MACHINE SETUP ==========

# Run any just target remotely on the live VM
vm_just *ARGS:
	ssh -p {{SSH_PORT}} {{SSH_USER}}@{{SSH_HOST}} "bash -l -c 'cd {{REPO_DIR}} && nix --extra-experimental-features \"nix-command flakes\" run nixpkgs#just -- {{ARGS}}'"

# Open interactive shell on VM with flake features and repo loaded
vm_just_shell:
	ssh -t -p {{SSH_PORT}} {{SSH_USER}}@{{SSH_HOST}} "cd {{REPO_DIR}} && nix --extra-experimental-features 'nix-command flakes' shell nixpkgs#just -c bash"

# Update the flake lock file
update:
	nix flake update

# Run garbage collection to clean up old builds
clean:
	nix-collect-garbage

# Format all files using pre-commit hooks
fmt:
	pre-commit run --all-files

# ========== DEVELOPMENT ==========
vm_prerequisites:
	@echo "Old sersion did: nix-shell -p qemu qemu-utils OVMF rage sops yq-go"
	@echo "Now, just run: nix develop"
	nix develop

# ========== VM INSTALLATION ==========
vm_prepare:
	mkdir -p $HOME/vms/nixos
	curl -L -o $HOME/vms/nixos/nixos-minimal.iso https://channels.nixos.org/nixos-24.11/latest-nixos-minimal-x86_64-linux.iso
	cp -v $(nix-build '<nixpkgs>' -A OVMF.fd)/FV/OVMF_CODE.fd $HOME/vms/nixos/
	cp -v $(nix-build '<nixpkgs>' -A OVMF.fd)/FV/OVMF_VARS.fd $HOME/vms/nixos/uefi_vars.fd
	chmod 644 $HOME/vms/nixos/*.fd
	qemu-img create -f qcow2 $HOME/vms/nixos/nixos-vm.qcow2 30G
	@echo "✅ VM disk prepared. Run 'just vm_run_installer'."

prepare-rescue-env:
	nix profile add --extra-experimental-features 'nix-command flakes' \
		nixpkgs#git \
		nixpkgs#just \
		nixpkgs#coreutils \
		nixpkgs#util-linux \
		nixpkgs#e2fsprogs \
		nixpkgs#openssh \
		nixpkgs#nixos-install-tools \
		nixpkgs#shadow \
		nixpkgs#inetutils \
		nixpkgs#procps \
		nixpkgs#iproute2 \
		nixpkgs#ncurses
	echo "✅ Tools geïnstalleerd:"


# Start live installer VM
vm_run_installer:
	qemu-system-x86_64 \
		-enable-kvm \
		-m 8G \
		-drive if=pflash,format=raw,readonly=on,file=$HOME/vms/nixos/OVMF_CODE.fd \
		-drive if=pflash,format=raw,file=$HOME/vms/nixos/uefi_vars.fd \
		-drive if=virtio,file=$HOME/vms/nixos/nixos-vm.qcow2,format=qcow2 \
		-cdrom $HOME/vms/nixos/nixos-minimal.iso \
		-boot d \
		-nic user,model=virtio-net-pci,hostfwd=tcp::2222-:22
	@echo "🔑 ssh -p 2222 nixos@localhost to access the live installer."

# Partition disk on live installer
vm_partition:
	sudo -i nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko -- --mode zap_create_mount ./nixos/modules/disk-layouts/generic-vm.nix
	@echo "✅ Partitioning done."


# Install Age key in correct location (on live installer)
install-root-key:
	sudo mkdir -p /root/.config/sops/age
	sudo cp ~/keys.txt /root/.config/sops/age/keys.txt
	sudo chmod 600 /root/.config/sops/age/keys.txt
	@echo "✅ Age private key ready for nixos-install"


# Install Age key remotely on live installer
remote-install-root-key:
	ssh -p 2222 nixos@localhost 'cd {{REPO_DIR}} && nix --extra-experimental-features "nix-command flakes" run nixpkgs#just -- install-root-key'


# Check if secrets are ready. Run at the host before doing bootstrap-vm 
check-deployable-vm:
	@echo "🔍 Validating declarative VM secrets setup..."
	@SECRET_FILE="nixos/secrets/generic-vm-eelco-secrets.yaml"; \
	if [ ! -f "$SECRET_FILE" ]; then \
		echo "❌ Secret file $SECRET_FILE does not exist"; exit 1; \
	fi; \
	if ! command -v sops >/dev/null; then \
		echo "❌ sops is not installed"; exit 1; \
	fi; \
	echo "🔓 Decrypting secrets..."; \
	SOPS_AGE_KEY_FILE=/dev/null sops -d "$SECRET_FILE" > /tmp/decrypted.yaml || { echo "❌ Failed to decrypt"; exit 1; }; \
	if ! grep -q "^age_key:" /tmp/decrypted.yaml; then \
		echo "❌ Decrypted secret is missing 'age_key'"; exit 1; \
	fi; \
	if ! grep -q "^id_ed25519:" /tmp/decrypted.yaml; then \
		echo "❌ Decrypted secret is missing 'id_ed25519'"; exit 1; \
	fi; \
	echo "✅ Secret file contains required keys and can be decrypted declaratively"

# ========== SHARED BOOTSTRAP LOGIC ==========

# Shared: Copy keys, repo, clone
bootstrap-base:
	@echo "📡 Copying ssh key to allow password less login..."
	just ssh-copy-key
	@echo "📡 Pushing Age key to live installer..."
	just push-key
	@echo "📂 Pushing repo to live installer..."
	just push-repo
	@echo "📂 Cloning repo on live installer..."
	just clone-repo

# ========== TARGET-SPECIFIC BOOTSTRAPS ==========

# For VM with /dev/vda
bootstrap-generic-vm:
	just bootstrap-base
	@echo "💽 Partitioning disk for VM..."
	just vm_just vm_partition
	@echo "🔑 Installing Age key in system path..."
	just install-age-key
	@echo "🚀 Running NixOS installation..."
	just vm_just vm_install
	@echo "✅ VM bootstrap complete! You can start it with: just vm_run"

# Bootstraps a physical laptop with live installer.
# Requires: 
# - SSH access to the live installer as root
# - .env.<HOST> with correct SSH_HOST/PORT
# - ./nixos/disks/<HOST>.nix defined
# - keys.txt in ~/.config/sops/age/
bootstrap-laptop HOST:
	just bootstrap-base
	@echo " Partitioning disk for laptop {{HOST}}..."
	just vm_just partition {{HOST}}
	@echo "🔑 Installing Age key in /mnt on target..."
	just install-age-key-mnt
	@echo "🚀 Before running the NixOS installation, generate your hardware configuration..."
	#just vm_just install {{HOST}}
	@echo "✅ {{HOST}} bootstrap complete! Reboot the machine."
# Legacy shortcut
bootstrap-vm: bootstrap-generic-vm

# Bootstrap a rescue environment for a physical machine.
bootstrap-rescue HOST:
	just bootstrap-base
	@echo "💥 Partitioneren van disks voor {{HOST}}..."
	just vm_just partition {{HOST}}
	@echo "🔐 Installeren van age-key in /mnt..."
	just install-age-key-mnt
	@echo "✅ Rescue bootstrap voor {{HOST}} voltooid!"

# Bootstrap NixOS install over existing Linux (e.g. Ubuntu)
bootstrap-ubuntu HOST:
	just bootstrap-base
	@echo "⚙️  Installing Nix on {{HOST}} via Determinate installer..."
	ssh root@{{SSH_HOST}} 'bash -l -c "\
	  set -e && \
	  if ! command -v nix >/dev/null; then \
	    curl -L -o nix-installer https://install.determinate.systems/nix/tag/v3.8.2/nix-installer-x86_64-linux && \
	    chmod +x nix-installer && \
	    ./nix-installer install && \
	    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh; \
	  fi"'
	@echo "✅ Ubuntu system is now ready for NixOS installation."

# Run nixos-install from live installer
vm_install:
	sudo nixos-install --flake .#generic-vm
	@echo "✅ NixOS installed."

# Boot VM from installed disk
vm_run:
	qemu-system-x86_64 \
		-enable-kvm \
		-m 8G \
		-smp 2 \
		-cpu host \
		-drive if=pflash,format=raw,readonly=on,file=$HOME/vms/nixos/OVMF_CODE.fd \
		-drive if=pflash,format=raw,file=$HOME/vms/nixos/uefi_vars.fd \
		-drive if=virtio,file=$HOME/vms/nixos/nixos-vm.qcow2,format=qcow2 \
		-boot c \
		-nic user,model=virtio-net-pci,hostfwd=tcp::2222-:22

# Optional GPU accelerated VM run
vm_run_gpu:
	qemu-system-x86_64 \
		-enable-kvm \
		-m 8G \
		-smp 4 \
		-cpu host \
		-device virtio-vga,virgl=on \
		-device virtio-tablet \
		-device virtio-keyboard-pci \
		-display gtk,gl=on \
		-drive if=pflash,format=raw,readonly=on,file=$HOME/vms/nixos/OVMF_CODE.fd \
		-drive if=pflash,format=raw,file=$HOME/vms/nixos/uefi_vars.fd \
		-drive if=virtio,file=$HOME/vms/nixos/nixos-vm.qcow2,format=qcow2 \
		-boot c \
		-nic user,model=virtio-net-pci

# Reset VM files to start over
vm_reset:
	@echo "🚀 Cleaning old VM virtual drives..."
	@if [ -d "${HOME}/vms" ]; then \
		rm -rv "${HOME}/vms"; \
		echo "🗑️  VM files removed."; \
	else \
		echo "🔁 No VM files found to remove."; \
	fi
	@echo "✅ Clean now. Start fresh with 'just vm_prepare'."


# ========== SOPS ENCRYPTION HELPERS (Age only) ==========

encrypt SECRET:
	if [ -z "{{SECRET}}" ]; then echo "❌ Specify a secret file"; exit 1; fi
	sops -e --age "$(rage-keygen -y ~/.config/sops/age/keys.txt)" -i nixos/secrets/{{SECRET}}


# ========== LIVE INSTALLATION ==========
partition HOST:
	sudo -i nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko -- --flake ~/elixos#{{HOST}} --mode zap_create_mount
	@echo "✅ Partitioning for {{HOST}}."

partition-dry HOST:
	nix run --extra-experimental-features 'nix-command flakes' github:nix-community/disko -- --flake ~/elixos#{{HOST}} --dry-run --mode zap_create_mount
	@echo "🧪 Dry run completed for {{HOST}}."

# ===== MOUNT HELPERS (SAFE) =====

# Mount bestaande partities volgens je disko-config, zonder te zappen of te (her)formatteren
mount HOST:
	sudo -i nix --extra-experimental-features 'nix-command flakes' \
	  run github:nix-community/disko -- --flake ~/elixos#{{HOST}} --mode mount
	@echo "✅ Mounted {{HOST}} on /mnt according to disko-config"

# Unmount alles onder /mnt (handig bij opnieuw proberen)
umount-all:
	- sudo swapoff -a
	- sudo umount -Rl /mnt || true
	@echo "✅ Everything under /mnt unmounted"

# (Optional) /nix to disk bind to prevent RAM shortage
bind-nix:
	sudo mkdir -p /mnt/nix
	# Copy existing /nix to /mnt/nix if it exists, otherwise just copy contents
	sudo sh -c '( cd /nix 2>/dev/null && tar cf - . ) | ( cd /mnt/nix && tar xpf - ) || cp -a /nix/. /mnt/nix/.'
	sudo mount --bind /mnt/nix /nix
	sudo mkdir -p /nix/var/nix/daemon-socket
	sudo chmod 755 /nix/var/nix/daemon-socket
	@echo "✅ /nix mounted to /mnt/nix and bound to /nix"

# 🛠 Generate hardware configuration (after partitioning!)
generate-hardware-config:
	sudo nixos-generate-config --root /mnt

# 💡 Reminder: after running `generate-hardware-config`, copy
# the generated `/mnt/etc/nixos/hardware-configuration.nix`
# into `nixos/hardware/tongfang/hardware-configuration.nix`

install HOST:
	@echo "🔐 Copying age key to target..."
	mkdir -p /mnt/etc/sops/age
	cp /root/keys.txt /mnt/etc/sops/age/keys.txt
	chmod 400 /mnt/etc/sops/age/keys.txt
	@echo "🚀 Building system for {{HOST}}..."
	nix --extra-experimental-features 'nix-command flakes' build .#nixosConfigurations.{{HOST}}.config.system.build.toplevel --out-link result-{{HOST}}
	@echo "🚀 Running nixos-install for {{HOST}}..."
	nixos-install --system result-{{HOST}} --no-root-passwd
	@echo "✅ {{HOST}} is now installed!"


install_server HOST:
	install_nix_installer_on_ubuntu
	build_on_ubuntu {{HOST}}
	install_on_ubuntu {{HOST}}

# 🔨 Local build (within Ubuntu on the currrent machine)
build_on_ubuntu HOST:
	@echo "🔨 Locally building system for {{HOST}} on Ubuntu..."
	bash scripts/bootstrap/build-on-ubuntu.sh {{HOST}}

# 💾 Lcal install (within Ubuntu on the current machine)
install_on_ubuntu HOST:
	@echo "💾 Locally installing system for {{HOST}} on Ubuntu..."
	bash scripts/install/install-over-ubuntu.sh {{HOST}}

# Install the nix installer on a server with ubuntu installed
install_nix_installer_on_ubuntu: 
	scripts/bootstrap/install-nix.sh

switch HOST:
	sudo nixos-rebuild switch --flake .#{{HOST}}

# Run Home Manager for a specific USER@HOST
home USER HOST:
	sudo -u {{USER}} -H home-manager switch --flake .#{{USER}}@{{HOST}}


# ========== NETWORK INSTALL HELPERS ==========
ssh-copy-key:
	@echo "📤 Creating .ssh dir and copying authorized_keys to remote"
	ssh -p {{SSH_PORT}} {{SSH_USER}}@{{SSH_HOST}} 'mkdir -p ~/.ssh && chmod 700 ~/.ssh'
	scp -P {{SSH_PORT}} ~/.ssh/id_ed25519.pub {{SSH_USER}}@{{SSH_HOST}}:~/.ssh/authorized_keys
	ssh -p {{SSH_PORT}} {{SSH_USER}}@{{SSH_HOST}} 'chmod 600 ~/.ssh/authorized_keys'
	@echo "✅ SSH key installed successfully"

push-key:
	scp -P {{SSH_PORT}} ~/.config/sops/age/keys.txt {{SSH_USER}}@{{SSH_HOST}}:~/keys.txt

push-repo:
	ssh -p {{SSH_PORT}} {{SSH_USER}}@{{SSH_HOST}} 'mkdir -p /tmp/elixos.git && git init --bare /tmp/elixos.git'
	git push ssh://{{SSH_USER}}@{{SSH_HOST}}:{{SSH_PORT}}/tmp/elixos.git main

clone-repo:
	ssh -p {{SSH_PORT}} {{SSH_USER}}@{{SSH_HOST}} 'git clone -b main /tmp/elixos.git {{REPO_DIR}} || true'

install-age-key-mnt:
	ssh -t -p {{SSH_PORT}} {{SSH_USER}}@{{SSH_HOST}} \
		'sudo mkdir -p /mnt/etc/sops/age && \
		sudo cp -v ~/keys.txt /mnt/etc/sops/age/keys.txt && \
		sudo chmod 400 /mnt/etc/sops/age/keys.txt && \
		echo "✅ Age key installed in target root (/mnt)"'

install-age-key:
	ssh -t -p {{SSH_PORT}} {{SSH_USER}}@{{SSH_HOST}} \
		'sudo mkdir -p /etc/sops/age && \
		sudo cp -v ~/keys.txt /etc/sops/age/keys.txt && \
		sudo chmod 400 /etc/sops/age/keys.txt && \
		echo "✅ Age key installed in target root (/)"'

install-user-age-key:
	ssh -t -p {{SSH_PORT}} {{SSH_USER}}@{{SSH_HOST}} \
		'mkdir -p ~/.config/sops/age && \
		cp -v ~/keys.txt ~/.config/sops/age/keys.txt && \
		chmod 400 ~/.config/sops/age/keys.txt && \
		echo "✅ Age key installed in user config (~/.config/sops/age)"'

post-boot-setup HOST USER:
	just load-env {{HOST}}
	just ssh-copy-key
	just push-key
	just push-repo
	just clone-repo
	just install-age-key
	just install-user-age-key
	@echo "🚀 Initial setup complete!"
	@echo ""
	@echo "👉 Now run the following on the VM as user '{{USER}}':"
	@echo "   cd {{REPO_DIR}} && sudo nixos-rebuild switch --flake .#{{HOST}}"
	@echo ""
	@echo "This will activate the full configuration, including SSH key generation."


# ========== SECRET MANAGEMENT ==========
# Create a new secret file
make-secret HOST USER:
    just _make-ssh-secret {{HOST}} {{USER}} id_ed25519_{{USER}}_{{HOST}}

_make-ssh-secret HOST USER KEY_NAME:
    @echo "🔐 Preparing secrets for HOST={{HOST}}, USER={{USER}}, KEY_NAME={{KEY_NAME}}" && \
    TMP_DIR=$(mktemp -d) && \
    AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt" && \
    echo "🔐 Extracting public age key from file $AGE_KEY_FILE" && \
    AGE_PUB_KEY="$(rage-keygen -y $AGE_KEY_FILE)" && \
    echo "🔐 Obtained public age key $AGE_PUB_KEY" && \
    SSH_KEY_FILE="$TMP_DIR/{{KEY_NAME}}" && \
    SECRET_FILE="nixos/secrets/{{KEY_NAME}}.yaml" && \
    echo "🔑 Generating SSH key $SSH_KEY_FILE if needed..." && \
    if [ ! -f "$SSH_KEY_FILE" ]; then \
        ssh-keygen -t ed25519 -N "" -f "$SSH_KEY_FILE" -C "{{USER}}@{{HOST}}"; \
    else \
        echo "🔁 SSH key already exists"; \
    fi && \
    echo "🔐 Creating secret YAML → $SECRET_FILE" && \
    mkdir -p nixos/secrets && \
    echo "✍️  Building user secret file..." && \
    echo "{{KEY_NAME}}: |" > "$SECRET_FILE" && \
    sed 's/^/  /' "$SSH_KEY_FILE" >> "$SECRET_FILE" && \
    sops --encrypt --input-type=yaml --output-type=yaml --age "$AGE_PUB_KEY" -i "$SECRET_FILE" && \
    echo "✅ Encrypted $SECRET_FILE" && \
    echo "🧹 Cleaning up..." && \
    rm -rf "$TMP_DIR"

decrypt-secret HOST USER:
    just _decrypt-secret-with-key {{HOST}} {{USER}} id_ed25519_{{USER}}_{{HOST}}

_decrypt-secret-with-key HOST USER KEY_NAME:
    @echo "🔓 Decrypting secret for HOST={{HOST}}, USER={{USER}}, KEY_NAME={{KEY_NAME}}" && \
    FILE="nixos/secrets/{{KEY_NAME}}.yaml" && \
    if [ ! -f "$FILE" ]; then \
        echo "❌ $FILE not found"; exit 1; \
    fi && \
    echo "📤 Decrypted content for key {{KEY_NAME}}:" && \
    sops -d "$FILE" | yq -r ".\"{{KEY_NAME}}\""

# ---- VPN helpers. Assume default Surfshark with WireGuard (wg-quick) ----

# Generate a WireGuard keypair for provider and backend (only if it doesn't exist yet)
gen-vpn-keypair PROVIDER="surfshark" BACKEND="wg":
	@bash ./scripts/vpn/gen-vpn-keypair.sh {{PROVIDER}} {{BACKEND}}

# Convention: interfaces are named wg-surfshark-<loc>, e.g. wg-surfshark-nl, wg-surfshark-bk, wg-surfshark-sg

vpn-list ARG="":
	@bash ./scripts/vpn/vpn-list.sh {{ARG}}

vpn-on LOC="nl":
	@bash ./scripts/vpn/vpn-on.sh {{LOC}}

vpn-off:
	@bash ./scripts/vpn/vpn-off.sh

vpn-status:
	@bash ./scripts/vpn/vpn-status.sh

# Show IP location using ipinfo.io
vpn-location:
	@curl https://ipinfo.io


# ========== VALIDATION ==========
check-install HOST USER:
	@echo "🔍 Checking /mnt-based install for HOST={{HOST}}, USER={{USER}}..."
	@if [ ! -s /mnt/etc/sops/age/keys.txt ]; then \
		echo "❌ /mnt/etc/sops/age/keys.txt is missing or empty"; exit 1; \
	else echo "✅ Age key is present"; fi
	@KEY="/mnt/home/{{USER}}/.ssh/id_ed25519"; \
	if [ ! -s "$KEY" ]; then \
		echo "❌ SSH private key ($KEY) is missing or empty"; exit 1; \
	else echo "✅ SSH private key is present"; fi
	@PUB="/mnt/home/{{USER}}/.ssh/id_ed25519.pub"; \
	if [ ! -s "$PUB" ]; then \
		echo "⚠️ SSH public key ($PUB) is missing or empty (might be generated after boot)"; \
	else echo "✅ SSH public key is present"; fi
	@echo "✅ Basic post-install checks complete for {{HOST}}/{{USER}}"

# ========== HELPERS ==========
load-env HOST:
	@echo "🔄 Loading environment for {{HOST}}..." && \
	test -f .env.{{HOST}} && export $(cat .env.{{HOST}} | grep '^export ' | cut -d' ' -f2- | xargs) || echo "⚠️ .env.{{HOST}} not found."

# -- hyperland

reload-waybar:
    pkill waybar && waybar &

switch-theme theme:
    HOME_THEME={{theme}} home-manager switch --flake ".#eelco@$(hostname)"
    pkill waybar && waybar &


# Set a specific wallpaper by path (must be in ~/.config/wallpapers or pass full path)
# - Works with filename (e.g. "default.png") or path ("/path/to/img.png", "~/img.png", "./img.png")
# Set wallpaper by name or path (extensie optioneel: probeert .png, dan .jpg)
wp-set FILE="default":
	~/.local/bin/wallpaper-set.sh {{FILE}}

# List available wallpapers (multi-column)
wp-list:
	~/.local/bin/wallpaper-list.sh

wp-random:
	~/.local/bin/wallpaper-random.sh

wp-effect:
	~/.local/bin/wallpaper-effects.sh

wp-random:
	~/.local/bin/wallpaper-random.sh

# Clear generated cache
wp-cache-clear:
	~/.local/bin/wallpaper-cache.sh

wp-fetch:
	~/.local/bin/fetch-wallpapers.sh

wp-fetch-now:   # start de systemd service handmatig
	systemctl --user start waypaper-fetch.service

wp-fetch-logs:
	journalctl --user -u waypaper-fetch -e --no-pager

