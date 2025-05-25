# ========== DEFAULT CONFIGURATION ========== 
SSH_USER := env("SSH_USER", "root")
SSH_PORT := env("SSH_PORT", "22")
LAPTOP_IP := env("LAPTOP_IP", "192.168.2.3")

REPO_DIR := "~/elixos"

# ========== GENERAL ==========
default:
	just --list --unsorted

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

# ========== NETWORK INSTALL HELPERS ==========
push-key:
	scp -P {{SSH_PORT}} ~/.config/sops/age/keys.txt {{SSH_USER}}@{{LAPTOP_IP}}:/home/{{SSH_USER}}/keys.txt

push-repo:
	ssh -p {{SSH_PORT}} {{SSH_USER}}@{{LAPTOP_IP}} 'mkdir -p /tmp/elixos.git && git init --bare /tmp/elixos.git'
	git push ssh://{{SSH_USER}}@{{LAPTOP_IP}}:{{SSH_PORT}}/tmp/elixos.git main

clone-repo:
	ssh -p {{SSH_PORT}} {{SSH_USER}}@{{LAPTOP_IP}} 'git clone -b main /tmp/elixos.git ~/elixos || true'

install-age-key:
	ssh -p {{SSH_PORT}} {{SSH_USER}}@{{LAPTOP_IP}} \
	  'sudo mkdir -p /etc/sops/age && \
	   sudo mv /home/{{SSH_USER}}/keys.txt /etc/sops/age/keys.txt && \
	   sudo chmod 400 /etc/sops/age/keys.txt && \
	   echo "✅ Age key installed on target"'

post-boot-setup HOST:
	just load-env {{HOST}}
	just push-key
	just push-repo
	just clone-repo
	just install-age-key
	@echo "🚀 Ready to run nixos-rebuild on {{HOST}}"

# ========== SECRET MANAGEMENT ==========
make-secret HOST USER:
	@echo "🔐 Preparing secrets for HOST={{HOST}}, USER={{USER}}"; \
	AGE_KEY_FILE="${HOME}/.config/sops/age/keys.txt"; \
	AGE_PUB_KEY="$(rage-keygen -y $AGE_KEY_FILE)"; \
	SSH_KEY_FILE="${HOME}/.ssh/ssh_key_{{HOST}}_{{USER}}"; \
	SECRET_FILE="nixos/secrets/{{HOST}}-{{USER}}-secrets.yaml"; \
	AGE_KEY_PLAIN="nixos/secrets/age_key.yaml.plain"; \
	AGE_KEY_FILE_OUT="nixos/secrets/age_key.yaml"; \
	if [ ! -f "$SSH_KEY_FILE" ]; then \
		ssh-keygen -t ed25519 -N "" -f "$SSH_KEY_FILE" -C "{{USER}}@{{HOST}}"; \
	else echo "🔁 SSH key already exists"; fi; \
	echo "age_key: |" > "$SECRET_FILE"; \
	sed 's/^/  /' "$AGE_KEY_FILE" >> "$SECRET_FILE"; \
	echo "id_ed25519_{{USER}}: |" >> "$SECRET_FILE"; \
	sed 's/^/  /' "$SSH_KEY_FILE" >> "$SECRET_FILE"; \
	sops --encrypt --age "$AGE_PUB_KEY" -i "$SECRET_FILE"; \
	echo "✅ Encrypted $SECRET_FILE"; \
	\
	echo "age_key: |" > "$AGE_KEY_PLAIN"; \
	sops --encrypt --output-type=yaml --age "$AGE_PUB_KEY" "$AGE_KEY_PLAIN" > "$AGE_KEY_FILE_OUT" && rm "$AGE_KEY_PLAIN"; \
	echo "✅ Encrypted $AGE_KEY_FILE_OUT"





decrypt-secret HOST USER:
	@SECRET_FILE="nixos/secrets/{{HOST}}-{{USER}}-secrets.yaml"; \
	SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt" nix shell nixpkgs#sops --command sops -d "$SECRET_FILE"

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
	test -f .env.{{HOST}} && export $(cat .env.{{HOST}} | xargs) || echo "⚠️ .env.{{HOST}} not found. Using fallback vars."
