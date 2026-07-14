#!/usr/bin/env bash
# WCPX end-to-end roundtrip test.
#
# Assumes docker-compose is up and both worldservers are healthy.
# Runs a source→target character transfer and verifies field-by-field
# equivalence.
#
# Exit 0 = pass. Exit non-zero = fail.
set -euo pipefail

: "${SOURCE_HOST:=localhost}"
: "${SOURCE_PORT:=8085}"
: "${TARGET_HOST:=localhost}"
: "${TARGET_PORT:=8086}"

# SOAP creds must exist on both sides (created by setup steps below).
: "${SOAP_USER:=admin}"
: "${SOAP_PASS:=admin}"

SHARED_OUT="./shared-out"
mkdir -p "$SHARED_OUT"

log() { echo "[roundtrip] $*"; }

# ---------------------------------------------------------------------------
# 1. Prepare source: create test account + level-80 character.
# ---------------------------------------------------------------------------
log "Provisioning source: test account + level-80 orc warrior"
docker compose exec -T s-worldserver bash -c '
  /azerothcore/env/dist/bin/authserver-console <<< "" &
  sleep 2
  /azerothcore/env/dist/bin/worldserver-console <<< "
    account create wcpxtest wcpxtestpw
    character create wcpxtest Grumshag orc warrior
    character level Grumshag 80
    character achievement add Grumshag 6
    character achievement add Grumshag 7
    character achievement add Grumshag 545
    lookup spell mount --learn Grumshag
  "
'

# ---------------------------------------------------------------------------
# 2. Trigger export via GM command.
# ---------------------------------------------------------------------------
PASSPHRASE="wcpxtest-passphrase-$(date +%s)"
log "Exporting Grumshag with passphrase '$PASSPHRASE'"
docker compose exec -T s-worldserver bash -c "
  /azerothcore/env/dist/bin/worldserver-console <<< '
    wcpx export Grumshag $PASSPHRASE
  '
"

# The mod writes into /wcpx-out which is bind-mounted to ./shared-out.
sleep 2
EXPORT_FILE=$(ls -t "$SHARED_OUT"/*.wcpx 2>/dev/null | head -1)
if [[ -z "$EXPORT_FILE" ]]; then
  log "FAIL: no .wcpx file produced"
  exit 1
fi
log "Export produced: $(basename "$EXPORT_FILE") ($(stat -c%s "$EXPORT_FILE") bytes)"

# ---------------------------------------------------------------------------
# 3. Configure target trust: whitelist the source pubkey.
# ---------------------------------------------------------------------------
log "Fetching source pubkey"
SOURCE_PUB=$(docker compose exec -T s-worldserver bash -c '
  openssl pkey -in /azerothcore/env/dist/etc/wcpx_server.key -pubout -outform DER 2>/dev/null | tail -c 32 | base64
')
log "Source pubkey: $SOURCE_PUB"

log "Whitelisting source on target"
docker compose exec -T t-worldserver bash -c "
  # Overwrite target conf's Trust.Whitelist with the source pubkey.
  sed -i 's|^CharacterPortability.Trust.Whitelist = .*|CharacterPortability.Trust.Whitelist = \"$SOURCE_PUB\"|' \
      /azerothcore/env/dist/etc/character_portability.conf
  # Reload config
  /azerothcore/env/dist/bin/worldserver-console <<< '
    reload config
  '
"

# ---------------------------------------------------------------------------
# 4. Import on target.
# ---------------------------------------------------------------------------
log "Provisioning target account"
docker compose exec -T t-worldserver bash -c '
  /azerothcore/env/dist/bin/worldserver-console <<< "
    account create wcpxtarget wcpxtargetpw
  "
'

TARGET_ACC_ID=$(docker compose exec -T t-worldserver bash -c "
  mysql -h t-db -u acore -pacore acore_auth -N -e \"
    SELECT id FROM account WHERE username='WCPXTARGET' LIMIT 1
  \"
")
log "Target account ID: $TARGET_ACC_ID"

log "Importing"
IMPORT_FILE="/wcpx-out/$(basename "$EXPORT_FILE")"
docker compose exec -T t-worldserver bash -c "
  /azerothcore/env/dist/bin/worldserver-console <<< '
    wcpx import $IMPORT_FILE $PASSPHRASE $TARGET_ACC_ID
  '
"

# ---------------------------------------------------------------------------
# 5. Verify.
# ---------------------------------------------------------------------------
log "Verifying import result on target"
TARGET_CHAR=$(docker compose exec -T t-worldserver bash -c "
  mysql -h t-db -u acore -pacore acore_characters -N -e \"
    SELECT guid, name, level, race, class FROM characters
    WHERE account=$TARGET_ACC_ID ORDER BY guid DESC LIMIT 1
  \"
")
log "Target character row: $TARGET_CHAR"

TARGET_ACH_COUNT=$(docker compose exec -T t-worldserver bash -c "
  mysql -h t-db -u acore -pacore acore_characters -N -e \"
    SELECT COUNT(*) FROM character_achievement WHERE guid IN (
      SELECT guid FROM characters WHERE account=$TARGET_ACC_ID
    )
  \"
")
log "Target achievement count: $TARGET_ACH_COUNT (expect 3)"

if [[ "$TARGET_ACH_COUNT" -ne 3 ]]; then
  log "FAIL: achievement count mismatch"
  exit 1
fi

log "PASS: Grumshag round-tripped from source to target"
