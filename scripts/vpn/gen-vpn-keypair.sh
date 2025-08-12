#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <provider> <backend>"
    echo "Example: $0 surfshark wg"
    exit 1
fi

PROVIDER="$1"
BACKEND="$2"
BASE_DIR="nixos/secrets/vpn/${PROVIDER}/${BACKEND}"
PRIVATE_KEY="${BASE_DIR}/privatekey"
PUBLIC_KEY="${BASE_DIR}/publickey"
PLAIN_PRIVATE_KEY="${BASE_DIR}/privatekey.plain"

# Check if key already exists
if [ -f "$PRIVATE_KEY" ]; then
    echo "❌ Private key already exists at $PRIVATE_KEY"
    echo "   Aborting to avoid overwriting your registered key."
    exit 1
fi

echo "🔑 Generating WireGuard keypair for ${PROVIDER} (${BACKEND})..."
mkdir -p "$BASE_DIR"
wg genkey | tee "$PLAIN_PRIVATE_KEY" | wg pubkey > "$PUBLIC_KEY"

echo "🔒 Encrypting private key with sops..."
sops --encrypt --in-place "$PLAIN_PRIVATE_KEY"
mv -v "$PLAIN_PRIVATE_KEY" "$PRIVATE_KEY"

echo "✅ Done. Public key is:"
cat "$PUBLIC_KEY"
echo "⚠️  Add the public key above to your ${PROVIDER} (${BACKEND}) setup page."
