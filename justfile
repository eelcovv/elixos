# ========== GENERAL ==========
default:
	just --list --unsorted

# Install pre-requisite packages (optional, local)
vm_prerequisite_install:
	nix-shell -p qemu qemu-utils OVMF rage sops

# Update & maintenance
update:
	nix flake update

clean:
	nix-collect-garbage

fmt:
	pre-commit run --all-files

# ========== VM INSTALLATION WORKFLOW ==========

# Step 1: Prepare VM disk, ISO and UEFI vars
vm_prepare:
	mkdir -p $HOME/vms/nixos
	curl -L -o $HOME/vms/nixos/nixos-minimal.iso https://channels.nixos.org/nixos-24.11/latest-nixos-minimal-x86_64-linux.iso
	cp -v $(nix-build '<nixpkgs>' -A OVMF.fd)/FV/OVMF_CODE.fd $HOME/vms/nixos/
	cp -v $(nix-build '<nixpkgs>' -A OVMF.fd)/FV/OVMF_VARS.fd $HOME/vms/nixos/uefi_vars.fd
	chmod 644 $HOME/vms/nixos/*.fd
	qemu-img create -f qcow2 $HOME/vms/nixos/nixos-vm.qcow2 30G
	@echo "✅ VM disk prepared. Run 'just vm_run_installer' to start."

# Step 2: Run the VM installer ISO
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

# Step 3: Partition disk from live installer
vm_partition:
	sudo nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko -- --mode zap_create_mount ./nixos/modules/disk-layouts/generic-vm.nix
	@echo "✅ Partitioning complete."

# Step 4: Push Age key from host to live installer
push-key:
	scp -P 2222 ~/.config/sops/age/keys.txt nixos@localhost:/home/nixos/keys.txt

# Step 5: Prepare Age key location for nixos-install on live installer
install-root-key:
	sudo mkdir -p /root/.config/sops/age
	sudo cp /home/nixos/keys.txt /root/.config/sops/age/keys.txt
	sudo chmod 600 /root/.config/sops/age/keys.txt
	@echo "✅ Age private key ready for nixos-install"

# Clone elixos repo on live installer (if missing)
clone-repo:
	ssh -p 2222 nixos@localhost 'git clone git@github.com:eelco/elixos.git || true'

# Remote exec: install root key (inside cloned repo)
remote-install-root-key:
	ssh -p 2222 nixos@localhost 'cd elixos && just install-root-key'

# Full bootstrap VM install flow
bootstrap-vm:
	@echo "📡 Copying Age key to live installer (localhost:2222)..."
	just push-key
	@echo "📂 Cloning elixos repo on live installer..."
	just clone-repo
	@echo "🔑 Installing Age key on live installer..."
	just remote-install-root-key
	@echo "💽 Partitioning VM disk..."
	ssh -p 2222 nixos@localhost 'cd elixos && just vm_partition'
	@echo "🚀 Running NixOS installation..."
	ssh -p 2222 nixos@localhost 'cd elixos && just vm_install'
	@echo "✅ VM bootstrap complete!"

# Step 6: Run nixos-install from live installer
vm_install:
	sudo nixos-install --flake .#generic-vm
	@echo "✅ NixOS installed on VM disk."

# Step 7: Boot VM from installed disk
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

# Optional: Boot VM with GPU acceleration
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

# Remove VM files to reset everything
vm_reset:
	rm -rv $HOME/vms
	@echo "🗑️ VM files removed. Run 'just vm_prepare' to start over."

# ========== SYSTEM BUILD TESTS ==========

local_tongfang:
	sudo nixos-rebuild switch --show-trace --flake .#tongfang

vm_build_tongfang:
	nixos-rebuild build-vm --flake .#tongfang

vm_build_singer:
	nixos-rebuild build-vm --flake .#singer

vm_build_generic-vm:
	nixos-rebuild build-vm --flake .#generic-vm

vm_switch_generic-vm-eelco:
	sudo nixos-rebuild switch --flake .#generic-vm

# ========== ENCRYPTION HELPERS ==========
encrypt-key:
	@echo "🔐 Converting ~/.ssh/id_ed25519 to YAML format..."
	@mkdir -p nixos/secrets
	@echo "id_ed25519: |" > nixos/secrets/generic-vm-secrets.yaml
	@cat ~/.ssh/id_ed25519 | sed 's/^/  /' >> nixos/secrets/generic-vm-secrets.yaml
	@echo "🔒 Encrypting with sops..."
	@nix shell nixpkgs#sops -c sops -e -i nixos/secrets/generic-vm-secrets.yaml
	@echo "✅ Secret encrypted to nixos/secrets/generic-vm-secrets.yaml"

show-key:
	@nix shell nixpkgs#sops -c sops -d nixos/secrets/generic-vm-secrets.yaml

decrypt-key:
	@nix shell nixpkgs#sops -c sops -d nixos/secrets/generic-vm-secrets.yaml > ~/.ssh/id_ed25519
	@chmod 400 ~/.ssh/id_ed25519
	@echo "✅ Decrypted ~/.ssh/id_ed25519"

# ========== LIVE INSTALL SSH HELP ==========
live_setup_ssh:
	sudo passwd nixos
	sudo systemctl start sshd
	ip a | grep 'inet ' | grep -v 127.0.0.1 || true
	@echo "✅ SSH ready. Use 'scp age-secret-key.txt nixos@<ip>' to transfer keys."
