#!/usr/bin/env bash
# Generate source + target Ed25519 keypairs and lay out the source-conf/
# target-conf/ directories that the compose file bind-mounts.
#
# Idempotent: skips existing keys.
set -euo pipefail

cd "$(dirname "$0")"

for side in source target; do
  mkdir -p "$side-conf"
  KEY="$side-conf/wcpx_server.key"
  if [[ -f "$KEY" ]]; then
    echo "[keys] $KEY already exists — leaving alone"
  else
    openssl genpkey -algorithm ED25519 -out "$KEY"
    chmod 600 "$KEY"
    echo "[keys] generated $KEY"
  fi

  # Copy the mod's default config into each side, with the key path fixed.
  cp ../../conf/character_portability.conf.dist "$side-conf/character_portability.conf"
  sed -i "s|env/dist/etc/wcpx_server.key|/azerothcore/env/dist/etc/wcpx_server.key|" \
      "$side-conf/character_portability.conf"
done

# Also print the target-side whitelist snippet the source needs (roundtrip.sh
# also does this automatically, but useful for manual runs).
echo
echo "Source pubkey (paste into target-conf/character_portability.conf ->"
echo "CharacterPortability.Trust.Whitelist if running manually):"
openssl pkey -in source-conf/wcpx_server.key -pubout -outform DER 2>/dev/null | tail -c 32 | base64
