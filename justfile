# ========== GENERAL ==========
default:
	just --list --unsorted

REPO_DIR := "~/elixos"

# ========== HOST MACHINE SETUP ==========

# Dev environment with QEMU, Rage, SOPS, OVMF
vm_prerequisites:
	nix-shell -p qemu qemu-utils OVMF rage sops

# Run any just target remotely on the live VM
vm_just TARGET:
	ssh -p 2222 nixos@localhost "cd {{REPO_DIR}} && nix --extra-experimental-features 'nix-command flakes' run nixpkgs#just -- {{TARGET}}"

# Open interactive shell on VM with flake features and repo loaded
vm_just_shell:
	ssh -t -p 2222 nixos@localhost "cd ~/elixos && nix --extra-experimental-features 'nix-command flakes' shell nixpkgs#just -c bash"

update:
	nix flake update

clean:
	nix-collect-garbage

fmt:
	pre-commit run --all-files

check-key HOST USER:
	SECRET_FILE="nixos/secrets/{{HOST}}-{{USER}}-secrets.yaml"; \
	nix shell nixpkgs#sops -c sops -d "$SECRET_FILE" > /tmp/id_check && chmod 400 /tmp/id_check; \
	ssh -i /tmp/id_check -p 2222 nixos@localhost hostname || echo "❌ Could not SSH with decrypted key"; \
	rm /tmp/id_check

# ========== VM INSTALLATION WORKFLOW ==========

# Prepare ISO, disk & UEFI vars
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
vm_partition_vm:
	sudo nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko -- --mode zap_create_mount ./nixos/modules/disk-layouts/generic-vm.nix
	@echo "✅ Partitioning done."

# Partition disk on singer 
partition HOST:
	sudo nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko -- --mode zap_create_mount ./nixos/disks/{{HOST}}.nix
	@echo "✅ Partitioning done for {{HOST}}."



# Push Age key to live installer
push-key:
	scp -P 2222 ~/.config/sops/age/keys.txt nixos@localhost:/home/nixos/keys.txt


# Install Age key in correct location (on live installer)
install-root-key:
	sudo mkdir -p /root/.config/sops/age
	sudo cp /home/nixos/keys.txt /root/.config/sops/age/keys.txt
	sudo chmod 600 /root/.config/sops/age/keys.txt
	@echo "✅ Age private key ready for nixos-install"

# Push repo to live installer via local bare repo
push-repo:
	ssh -p 2222 nixos@localhost 'mkdir -p /tmp/elixos.git && git init --bare /tmp/elixos.git'
	git push ssh://nixos@localhost:2222/tmp/elixos.git main

# Clone from /tmp/elixos.git into ~/elixos on live installer
clone-repo:
	ssh -p 2222 nixos@localhost 'git clone -b main /tmp/elixos.git ~/elixos || true'

push-key-vm:
	scp -P 2222 ~/.config/sops/age/keys.txt eelco@localhost:/home/nixos/keys.txt

push-repo-vm:
	ssh -p 2222 eelco@localhost 'mkdir -p /tmp/elixos.git && git init --bare /tmp/elixos.git'
	git push ssh://eelco@localhost:2222/tmp/elixos.git main

clone-repo-vm:
	ssh -p 2222 eelco@localhost 'git clone -b main /tmp/elixos.git ~/elixos || true'

# Install age key into /etc/sops/age on remote host (requires sudo)
install-age-key-vm:
	ssh -p 2222 eelco@localhost \
	  'sudo mkdir -p /etc/sops/age && \
	   sudo mv /home/nixos/keys.txt /etc/sops/age/keys.txt && \
	   sudo chmod 400 /etc/sops/age/keys.txt && \
	   echo "✅ Age key installed on VM"'

# === All-in-one step for real VM after boot ===
post-boot-setup HOST:
	just push-key-vm
	just install-age-key-vm
	just push-repo-vm
	just clone-repo-vm
	@echo "🚀 Ready to run nixos-rebuild on {{HOST}}"

# Install Age key remotely on live installer
remote-install-root-key:
	ssh -p 2222 nixos@localhost 'cd ~/elixos && nix --extra-experimental-features "nix-command flakes" run nixpkgs#just -- install-root-key'

check-deployable-vm HOST USER:
	@echo "🔍 Validating secrets for HOST={{HOST}}, USER={{USER}}..."
	@SECRET_FILE="nixos/secrets/{{HOST}}-{{USER}}-secrets.yaml"; \
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
	echo "✅ $SECRET_FILE is valid and decrypts correctly"

# Full bootstrap (key, repo, partition, install)
bootstrap-vm:
	@echo "📡 Pushing Age key to live installer..."
	just push-key
	@echo "📂 Pushing repo to live installer..."
	just push-repo
	@echo "📂 Cloning repo on live installer..."
	just clone-repo
	@echo "🔑 Installing Age key into /etc/sops..."
	just vm_just install-root-key
	@echo "💽 Partitioning disk..."
	just vm_just vm_partition_vm
	@echo "🚀 Running NixOS installation..."
	just vm_just vm_install
	@echo "✅ VM bootstrap complete!. You can start the vm now with just vm_run"

bootstrap-laptop HOST:
	@echo "📡 Pushing Age key..."
	just push-key
	@echo "💽 Partitioning disk..."
	just vm_partition {{HOST}}
	@echo "🚀 Installing system..."
	just install {{HOST}}


# Run nixos-install from live installer
vm_install:
	sudo nixos-install --flake .#generic-vm
	@echo "✅ NixOS installed."

install HOST:
	@echo "🔐 Copying age key to target..."
	mkdir -p /mnt/etc/sops/age
	cp /root/keys.txt /mnt/etc/sops/age/keys.txt
	chmod 400 /mnt/etc/sops/age/keys.txt
	@echo "🚀 Running nixos-install for {{HOST}}..."
	nixos-install --flake .#{{HOST}}
	@echo "✅ {{HOST}} is now installed!"


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
	rm -rv $HOME/vms
	@echo "🗑️ VM files removed. Start fresh with 'just vm_prepare'."

# ========== SOPS ENCRYPTION HELPERS (Age only) ==========

encrypt SECRET:
	if [ -z "{{SECRET}}" ]; then echo "❌ Specify a secret file"; exit 1; fi
	sops -e --age "$(rage-keygen -y ~/.config/sops/age/keys.txt)" -i nixos/secrets/{{SECRET}}

make-secret HOST USER:
	@echo "🔐 Preparing secrets for HOST={{HOST}}, USER={{USER}}"; \
	AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"; \
	echo "🔐 Extracting public age key from file $AGE_KEY_FILE"; \
	AGE_PUB_KEY="$(rage-keygen -y $AGE_KEY_FILE)"; \
	echo "🔐 Obtained public age key  $AGE_PUB_KEY"; \
	SSH_KEY_FILE="$HOME/.ssh/ssh_key_{{HOST}}_{{USER}}"; \
	SECRET_FILE="nixos/secrets/{{HOST}}-{{USER}}-secrets.yaml"; \
	echo "🔐 Checking SSH key: $SSH_KEY_FILE"; \
	if [ ! -f "$SSH_KEY_FILE" ]; then \
		ssh-keygen -t ed25519 -N "" -f "$SSH_KEY_FILE" -C "{{USER}}@{{HOST}}"; \
	else \
		echo "🔁 SSH key already exists"; \
	fi; \
	echo "🔐 Creating secret YAML → $SECRET_FILE"; \
	mkdir -p nixos/secrets; \
	echo "age_key: |" > "$SECRET_FILE"; \
	cat "$AGE_KEY_FILE" | sed 's/^/  /' >> "$SECRET_FILE"; \
	echo "id_ed25519: |" >> "$SECRET_FILE"; \
	cat "$SSH_KEY_FILE" | sed 's/^/  /' >> "$SECRET_FILE"; \
	sops -e --age "$AGE_PUB_KEY" -i "$SECRET_FILE"; \
	echo "✅ Encrypted $SECRET_FILE"

decrypt-secret HOST USER:
	@SECRET_FILE="nixos/secrets/{{HOST}}-{{USER}}-secrets.yaml"; \
	echo "🔓 Decrypting $SECRET_FILE..."; \
	SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt" nix shell nixpkgs#sops --command sops -d "$SECRET_FILE"



# ========== LIVE INSTALLER SSH SETUP ==========

live_setup_ssh:
	sudo passwd nixos
	sudo systemctl start sshd
	ip a | grep 'inet ' | grep -v 127.0.0.1


# Remove old SSH key for QEMU port
ssh_clear_known_host:
	ssh-keygen -R "[localhost]:2222"

# Add current user’s SSH key to live VM
ssh_authorize USER: 
	just ssh_clear_known_host
	ssh-copy-id -i ~/.ssh/id_ed25519.pub -p 2222 "{{USER}}@localhost"


# Test of de SOPS decryptie werkt op de live installer
# Controleer of SOPS decryptie werkt voor een gegeven HOST en USER (op de live installer)
check-decrypt HOST USER:
	ssh -p 2222 nixos@localhost "nix shell nixpkgs#sops -c sops -d nixos/secrets/{{HOST}}-{{USER}}-secrets.yaml | head"

remote-check-decrypt HOST USER:
	ssh -p 2222 nixos@localhost \
		"nix --extra-experimental-features 'nix-command flakes' shell nixpkgs#sops -c sops -d nixos/secrets/{{HOST}}-{{USER}}-secrets.yaml | head"



check-secrets:
	ssh -p 2222 nixos@localhost bash -c \
	echo "🔍 Checking /etc/sops/age/keys.txt"; \
	if [ -s /etc/sops/age/keys.txt ] && echo "✅ age key aanwezig" || echo "❌ age key is missing or empty"; \
	echo "🔍 Checking /home/eelco/.ssh/id_ed25519"; \
	if [ -s /home/eelco/.ssh/id_ed25519 ] && echo "✅ id_ed25519 aanwezig" || echo "❌ id_ed25519 is missing or empty"; \
	echo "🔍 Checking /home/eelco/.ssh/id_ed25519.pub"; \
	if [ -s /home/eelco/.ssh/id_ed25519.pub ] && echo "✅ id_ed25519.pub aanwezig" || echo "❌ id_ed25519.pub is missing or empty"';
