# mod-character-portability — PLAN

## Status
Scaffold + core code written 2026-07-14. Not yet compiled against a live AC tree.

## Layout
```
mod-character-portability/
├── README.md
├── PLAN.md
├── include.sh
├── conf/
│   └── character_portability.conf.dist
├── data/sql/db-characters/base/
│   └── 2026_07_14_00_wcpx_imported_files.sql
└── src/
    ├── CharacterPortability.h          — public interface
    ├── mod_character_portability_loader.cpp
    ├── CharacterPortability_Config.cpp — config load
    ├── CharacterPortability_Crypto.cpp — OpenSSL + libargon2
    ├── CharacterPortability_Codec.cpp  — WCPX file format + canonical JSON
    ├── CharacterPortability_Export.cpp — export path (DB → JSON → sign → encrypt)
    ├── CharacterPortability_Import.cpp — import path (parse → verify → decrypt → apply)
    └── CharacterPortability_Commands.cpp — GM commands
```

## Dependencies not in stock AC
- **libargon2**: `apt install libargon2-dev` on Debian/Ubuntu. Needs a
  `find_package(argon2)` addition to the module's CMake integration.
- OpenSSL 1.1.1+ (Ed25519 + AES-256-GCM) — AC already links OpenSSL, but
  vendor forks with older builds may need a bump.

## Known gaps in scaffold (Phase 2 work)
- `ApplyPayload` in Import inserts a bare `characters` row without going through
  `Player::Create` — this misses many derived fields (money, actionButtons,
  create_time, etc.). Should be reworked to use ObjectMgr's create pipeline
  with a PlayerCreateInfo derived from the payload.
- No CMakeLists.txt yet — relies on AC's module include.sh discovery.
- Payload parsing on import uses regex; fine for canonical-form JSON that
  we emit ourselves, but should be replaced with nlohmann/json (already an
  AC dep) for robustness.
- `character_talent.specMask` handling is simplified; real 3.3.5a talents
  need proper spec-index conversion.
- Web-API endpoints (`/api/wcpx/export`, `/api/wcpx/import`) not implemented —
  ship as FCMS handlers in Phase 2.
- No unit tests. Should add roundtrip test: build char → export → wipe →
  import → assert level/spells/achievements identical.

## Wakingdream production integration
- Pricing set via config: `Export.FreePerMonth = 1`, `Import.RequireTokenId = 1`
  with token issuance from FCMS Stripe integration (€25 per import).
- Trust mode: start with `whitelist`, seed with only Wakingdream's own key for
  Wakingdream→Wakingdream test transfers. Add other servers as they publish
  their pubkeys.

## References
- Spec: `../wcpx-spec/SPEC.md`
- AC module convention: `../mod-emerald-dream/` layout
