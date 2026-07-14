# Roundtrip test — two-server Docker rig

End-to-end test: build the mod into two AzerothCore instances (source and
target), create a level-80 character on the source, export to `.wcpx`,
import into the target, and diff the result.

**Not yet run.** The prep VPS lacks Docker; run this on the Netcup game
host (which does have Docker per Wakingdream's stack) or any Docker-
capable machine.

## Requirements

- Docker + Docker Compose v2 (`docker compose ...`)
- ~4 GiB free disk for two AC images
- 10-30 min for first build (AC compile inside the image is the bottleneck)

## Run

```bash
cd projects/wakingdream-modules/mod-character-portability/test/roundtrip
./setup-keys.sh          # generates Ed25519 keypairs for both sides
docker compose up -d --build
# wait ~30s for both worldservers to boot
./roundtrip.sh
docker compose down -v
```

Expected final line: `[roundtrip] PASS: Grumshag round-tripped from source to target`

## What it exercises

- Full mod compile inside the AC image (`libargon2-dev` gets added)
- Real DB tables (`characters`, `character_spell`, `character_achievement`,
  `character_reputation`, `character_skills`) on both sides
- Ed25519 sign on source, verify on target
- AES-256-GCM encrypt on source, decrypt on target
- Argon2id KDF on both ends (deterministic given identical passphrase +
  salt from file)
- Whitelist trust check on the target (source pubkey pre-approved)
- File-ID replay ledger (a second attempt to import the same file should
  fail — extend `roundtrip.sh` to test this if desired)

## Known limitations

- **`ApplyPayload` bypasses `Player::Create`.** The imported character has
  a bare `characters` row without money, starting action bar, glyph slots,
  etc. This is a known Phase-2 gap; see `PLAN.md`. The test verifies field
  parity for the fields we DO import (level, achievements, spells, ...).
- **cMaNGOS / TrinityCore-335 not tested here.** This harness is AC-only.
  Adapting to TC-335 is trivial (change base image); cMaNGOS needs the
  mod ported first (see `../../PORTING.md`).
- **AC GM-console command syntax may need tweaking.** The mod registers
  `.wcpx export/import/trust` chat commands, but the `worldserver-console`
  interactive prompt may not accept them exactly as shown. If the script
  fails at export, try issuing the command via `.` prefix or via SOAP
  (adapt the script accordingly).

## Alternative: manual SOAP

For debugging, you can skip the console and use AC's SOAP interface:

```bash
curl -X POST http://localhost:7878/soap/urn:AC \
  -u admin:admin \
  -d '<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">
        <SOAP-ENV:Body>
          <ns1:executeCommand xmlns:ns1="urn:AC">
            <command>wcpx export Grumshag mypassphrase</command>
          </ns1:executeCommand>
        </SOAP-ENV:Body>
      </SOAP-ENV:Envelope>'
```
