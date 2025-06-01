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
vm_just TARGET:
	ssh -p {{SSH_PORT}} {{SSH_USER}}@{{SSH_HOST}} "cd {{REPO_DIR}} && nix --extra-experimental-features 'nix-command flakes' run nixpkgs#just -- {{TARGET}}"

# Open interactive shell on VM with flake features and repo loaded
vm_just_shell:
	ssh -t -p {{SSH_PORT}} {{SSH_USER}}@{{SSH_HOST}} "cd {{REPO_DIR}} && nix --extra-experimental-features 'nix-command flakes' shell nixpkgs#just -c bash"

update:
	nix flake update

clean:
	nix-collect-garbage

fmt:
	pre-commit run --all-files

# ========== DEVELOPMENT ==========
vm_prerequisites:
	nix-shell -p qemu qemu-utils OVMF rage sops

# ========== VM INSTALLATION ==========
vm_prepare:
	mkdir -p $HOME/vms/nixos
	curl -L -o $HOME/vms/nixos/nixos-minimal.iso https://channels.nixos.org/nixos-24.11/latest-nixos-minimal-x86_64-linux.iso
	cp -v $(nix-build '<nixpkgs>' -A OVMF.fd)/FV/OVMF_CODE.fd $HOME/vms/nixos/
	cp -v $(nix-build '<nixpkgs>' -A OVMF.fd)/FV/OVMF_VARS.fd $HOME/vms/nixos/uefi_vars.fd
	chmod 644 $HOME/vms/nixos/*.fd
	qemu-img create -f qcow2 $HOME/vms/nixos/nixos-vm.qcow2 30G
	@echo "✅ VM disk prepared. Run 'just vm_run_installer'."

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
	sudo nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko -- --mode zap_create_mount ./nixos/modules/disk-layouts/generic-vm.nix
	@echo "✅ Partitioning done."


# Install Age key in correct location (on live installer)
install-root-key:
	sudo mkdir -p /root/.config/sops/age
	sudo cp /home/nixos/keys.txt /root/.config/sops/age/keys.txt
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

# Full bootstrap (key, repo, partition, install)
bootstrap-vm:
	@echo "📡 Copying ssh key to allow password less login..."
	just ssh-copy-key
	@echo "📡 Pushing Age key to live installer..."
	just push-key
	@echo "🔑 Installing Age key in system path..."
	just install-age-key
	@echo "📂 Pushing repo to live installer..."
	just push-repo
	@echo "📂 Cloning repo on live installer..."
	just clone-repo
	@echo "💽 Partitioning disk..."
	just vm_just vm_partition
	@echo "🚀 Running NixOS installation..."
	just vm_just vm_install
	@echo "✅ VM bootstrap complete!. You can start the vm now with just vm_run"

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
	sudo nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko -- --mode zap_create_mount ./nixos/disks/{{HOST}}.nix
	@echo "✅ Partitioning done for {{HOST}}."

install HOST:
	@echo "🔐 Copying age key to target..."
	mkdir -p /mnt/etc/sops/age
	cp /root/keys.txt /mnt/etc/sops/age/keys.txt
	chmod 400 /mnt/etc/sops/age/keys.txt
	@echo "🚀 Running nixos-install for {{HOST}}..."
	nixos-install --flake .#{{HOST}}
	@echo "✅ {{HOST}} is now installed!"

bootstrap-laptop HOST:
	just load-env {{HOST}}
	just partition {{HOST}}
	just install {{HOST}}

switch HOST:
	sudo nixos-rebuild switch --flake .#{{HOST}}

# ========== NETWORK INSTALL HELPERS ==========
ssh-copy-key:
	@echo "📤 Creating .ssh dir and copying authorized_keys to remote"
	ssh -p {{SSH_PORT}} {{SSH_USER}}@{{SSH_HOST}} 'mkdir -p ~/.ssh && chmod 700 ~/.ssh'
	scp -P {{SSH_PORT}} ~/.ssh/id_ed25519.pub {{SSH_USER}}@{{SSH_HOST}}:/home/{{SSH_USER}}/.ssh/authorized_keys
	ssh -p {{SSH_PORT}} {{SSH_USER}}@{{SSH_HOST}} 'chmod 600 ~/.ssh/authorized_keys'
	@echo "✅ SSH key installed successfully"

push-key:
	scp -P {{SSH_PORT}} ~/.config/sops/age/keys.txt {{SSH_USER}}@{{SSH_HOST}}:/home/{{SSH_USER}}/keys.txt

push-repo:
	ssh -p {{SSH_PORT}} {{SSH_USER}}@{{SSH_HOST}} 'mkdir -p /tmp/elixos.git && git init --bare /tmp/elixos.git'
	git push ssh://{{SSH_USER}}@{{SSH_HOST}}:{{SSH_PORT}}/tmp/elixos.git main

clone-repo:
	ssh -p {{SSH_PORT}} {{SSH_USER}}@{{SSH_HOST}} 'git clone -b main /tmp/elixos.git {{REPO_DIR}} || true'

install-age-key:
	ssh -p {{SSH_PORT}} {{SSH_USER}}@{{SSH_HOST}} \
	  'sudo mkdir -p /mnt/etc/sops/age && \
	   sudo mv /home/{{SSH_USER}}/keys.txt /mnt/etc/sops/age/keys.txt && \
	   sudo chmod 400 /mnt/etc/sops/age/keys.txt && \
	   echo "✅ Age key installed in target root (/mnt)"'

post-boot-setup HOST USER:
	just load-env {{HOST}}
	just push-key
	just push-repo
	just clone-repo
	just install-age-key
	just decrypt-ssh-key {{HOST}} {{USER}}
	@echo "🚀 Ready to run nixos-rebuild on {{HOST}} as {{USER}}"



decrypt-ssh-key HOST USER:
	@echo "🔓 Decrypting SSH key for {{USER}} on {{HOST}} and writing to ~/.ssh/id_ed25519..."
	ssh -p {{SSH_PORT}} {{SSH_USER}}@{{SSH_HOST}} \
		'SOPS_AGE_KEY_FILE=/etc/sops/age/keys.txt \
		sops -d {{REPO_DIR}}/nixos/secrets/{{HOST}}-{{USER}}-secrets.yaml | \
		yq -r .id_ed25519_{{USER}} > ~/.ssh/id_ed25519 && \
		chmod 600 ~/.ssh/id_ed25519 && \
		ssh-keygen -y -f ~/.ssh/id_ed25519 > ~/.ssh/id_ed25519.pub && \
		echo "✅ SSH keypair restored to ~/.ssh/id_ed25519[.pub]"'

# ========== SECRET MANAGEMENT ==========
make-secret HOST USER:
	@echo "🔐 Preparing secrets for HOST={{HOST}}, USER={{USER}}"; \
	AGE_KEY_FILE="${HOME}/.config/sops/age/keys.txt"; \
	echo "🔐 Extracting public age key from file $AGE_KEY_FILE"; \
	AGE_PUB_KEY="$(rage-keygen -y $AGE_KEY_FILE)"; \
	echo "🔐 Obtained public age key  $AGE_PUB_KEY"; \
	SSH_KEY_FILE="${HOME}/.ssh/ssh_key_{{HOST}}_{{USER}}"; \
	SECRET_FILE="nixos/secrets/{{HOST}}-{{USER}}-secrets.yaml"; \
	AGE_KEY_FILE_OUT="nixos/secrets/age_key.yaml"; \
	echo "🔑 Generating SSH key ${SSH_KEY_FILE} if needed..."; \
	if [ ! -f "$SSH_KEY_FILE" ]; then \
		ssh-keygen -t ed25519 -N "" -f "$SSH_KEY_FILE" -C "{{USER}}@{{HOST}}"; \
	else \
		echo "🔁 SSH key already exists"; \
	fi; \
	echo "🔐 Creating secret YAML → $SECRET_FILE"; \
	mkdir -p nixos/secrets; \
	echo "✍️  Building user secret file..."; \
	echo "id_ed25519_{{USER}}: |" > "$SECRET_FILE"; \
	sed 's/^/  /' "$SSH_KEY_FILE" >> "$SECRET_FILE"; \
	sops --encrypt --input-type=yaml --output-type=yaml --age "$AGE_PUB_KEY" -i "$SECRET_FILE"; \
	echo "✅ Encrypted $SECRET_FILE"; \
	\
	echo "✍️  Building and encrypting age_key.yaml..."; \
	echo "age_key: |" > "$AGE_KEY_FILE_OUT"; \
	sed 's/^/  /' "$AGE_KEY_FILE" >> "$AGE_KEY_FILE_OUT"; \
	sops --encrypt --input-type=yaml --output-type=yaml --age "$AGE_PUB_KEY" -i "$AGE_KEY_FILE_OUT"; \
	echo "✅ Encrypted $AGE_KEY_FILE_OUT"

decrypt-secret HOST USER:
	@SECRET_FILE="nixos/secrets/{{HOST}}-{{USER}}-secrets.yaml"; \
	echo "🔓 Decrypting $SECRET_FILE..."; \
	SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt" nix shell nixpkgs#sops --command sops -d "$SECRET_FILE"

check-age_key:
	@echo "🔍 Checking if age_key.yaml can be decrypted..."; \
	FILE="nixos/secrets/age_key.yaml"; \
	if [ ! -f "$FILE" ]; then \
		echo "❌ $FILE not found"; exit 1; \
	fi; \
	if SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt" nix shell nixpkgs#sops --command sops -d "$FILE" > /dev/null 2>&1; then \
		echo "✅ age_key.yaml is decryptable"; \
	else \
		echo "❌ Failed to decrypt age_key.yaml — wrong or missing key?"; exit 1; \
	fi

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
