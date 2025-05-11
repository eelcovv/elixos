# ========== GENERAL ==========
default:
	just --list --unsorted

# ========== HOST MACHINE SETUP ==========

# Dev environment with QEMU, Rage, SOPS, OVMF
vm_prerequisites:
	nix-shell -p qemu qemu-utils OVMF rage sops

# Update & maintenance
update:
	nix flake update

clean:
	nix-collect-garbage

fmt:
	pre-commit run --all-files

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
vm_partition:
	sudo nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko -- --mode zap_create_mount ./nixos/modules/disk-layouts/generic-vm.nix
	@echo "✅ Partitioning done."

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

# Install Age key remotely on live installer
remote-install-root-key:
	ssh -p 2222 nixos@localhost 'cd ~/elixos && just install-root-key'

# Full bootstrap (key, repo, partition, install)
bootstrap-vm:
	@echo "📡 Pushing Age key to live installer..."
	just push-key
	@echo "📂 Pushing repo to live installer..."
	just push-repo
	@echo "📂 Cloning repo on live installer..."
	just clone-repo
	@echo "🔑 Installing Age key..."
	just remote-install-root-key
	@echo "💽 Partitioning disk..."
	ssh -p 2222 nixos@localhost 'cd ~/elixos && just vm_partition'
	@echo "🚀 Running NixOS installation..."
	ssh -p 2222 nixos@localhost 'cd ~/elixos && just vm_install'
	@echo "✅ VM bootstrap complete!"

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
	rm -rv $HOME/vms
	@echo "🗑️ VM files removed. Start fresh with 'just vm_prepare'."

# ========== ENCRYPTION HELPERS ==========

encrypt-key:
	@echo "🔐 Converting ~/.ssh/id_ed25519 to YAML..."
	@mkdir -p nixos/secrets
	@echo "id_ed25519: |" > nixos/secrets/generic-vm-secrets.yaml
	@cat ~/.ssh/id_ed25519 | sed 's/^/  /' >> nixos/secrets/generic-vm-secrets.yaml
	@nix shell nixpkgs#sops -c sops -e -i nixos/secrets/generic-vm-secrets.yaml
	@echo "✅ Secret encrypted."

show-key:
	@nix shell nixpkgs#sops -c sops -d nixos/secrets/generic-vm-secrets.yaml

decrypt-key:
	@nix shell nixpkgs#sops -c sops -d nixos/secrets/generic-vm-secrets.yaml > ~/.ssh/id_ed25519
	@chmod 400 ~/.ssh/id_ed25519
	@echo "✅ Decrypted ~/.ssh/id_ed25519"

# ========== LIVE INSTALLER SSH SETUP ==========
live_setup_ssh:
	sudo passwd nixos
	sudo systemctl start sshd
	ip a | grep 'inet ' | grep -v 127.0.0.1

