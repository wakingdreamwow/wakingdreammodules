# mod-character-portability

Reference AzerothCore 3.3.5a implementation of the [WCPX](https://github.com/wakingdreamwow/wcpx-spec) character portability format.

Lets players export their character to a signed, encrypted `.wcpx` file, and
lets admins accept `.wcpx` files from other trusted servers as new characters
on this server.

## Feature summary

- **Export:** produces a `.wcpx` file containing level, XP, talents, spells
  (including mounts), achievements, reputation, skills, and titles. Items,
  gold, and bags are excluded by design.
- **Import:** consumes a `.wcpx` file signed by a trusted source-server
  public key, decrypts it with a player-supplied passphrase, and creates
  a new character in the target account.
- **Crypto:** Ed25519 signature (source-server key), AES-256-GCM payload
  encryption, Argon2id passphrase derivation.
- **Trust model:** per-server, decentralized. Configure `whitelist`,
  `tofu`, or `open` mode in `character_portability.conf`.
- **Rate limit:** one free export per account per 30 days by default;
  additional exports gated by the shop / paid-service integration your
  server chooses to wire up.
- **Replay protection:** each `(file_id, source_pubkey)` can only be imported
  once per server. Tracked in `wcpx_imported_files` on the characters DB.

## Not for players

This module ships GM commands and web-API endpoints, not player chat
commands. The intended integration is:

- **Player-facing:** a web UI (e.g. your server's control panel) calls
  the export/import endpoints. That web UI handles Stripe/PayPal for paid
  operations and enforces per-account rate limits.
- **Admin-facing:** `.wcpx export <charname> <passphrase>` and
  `.wcpx import <path> <passphrase>` GM commands for manual operation and
  debugging.

## Dependencies

- **OpenSSL** — already required by AzerothCore; used for Ed25519 signing
  and AES-256-GCM authenticated encryption.
- **libargon2** — passphrase key derivation. Distro package on Debian /
  Ubuntu: `apt install libargon2-dev`. Linked in `CMakeLists.txt` via
  `find_package(argon2)` or fallback pkg-config.

## Install

Standard AzerothCore module drop-in:

```
cd azerothcore-wotlk/modules
git clone https://github.com/wakingdreamwow/mod-character-portability.git
```

Rebuild worldserver, then:

```
cp modules/mod-character-portability/conf/character_portability.conf.dist \
   env/dist/etc/character_portability.conf
```

Edit config, then restart worldserver. The DB migration for
`wcpx_imported_files` runs automatically via the AC DB updater.

## Config quick reference

```conf
# Signing key (required). Generate with `openssl genpkey -algorithm ED25519`.
CharacterPortability.Server.PrivateKeyPath = "env/dist/etc/wcpx_server.key"

# Trust mode: "whitelist" | "tofu" | "open".
CharacterPortability.Trust.Mode = "whitelist"

# Whitelist trust: pubkeys in base64 (Ed25519, 44 chars each). Space-separated.
CharacterPortability.Trust.Whitelist = ""

# Rate limits.
CharacterPortability.Export.FreePerMonth = 1
CharacterPortability.Import.RequireTokenId = 1  # 1 = require paid-import token
```

## GM commands

- `.wcpx export <charname> <passphrase>` — writes a .wcpx file for the named
  character to `wcpx-exports/<charname>-<timestamp>.wcpx` under the worldserver
  working dir. Bypasses the free-per-month limit.
- `.wcpx import <path> <passphrase> <target_account>` — imports the file
  into the target account as a new character. Bypasses the paid-token check.

## Web API

Exposed via [FCMS](https://github.com/AzerothCore/mod-fcms) integration
when present:

- `POST /api/wcpx/export` — body: `{ character_id, passphrase }` →
  file download. Enforces free-per-month + paid-export-token.
- `POST /api/wcpx/import` — multipart: `.wcpx` file + `passphrase` +
  `paid_token` → returns new character_id on success.

## Schema

```sql
CREATE TABLE IF NOT EXISTS wcpx_imported_files (
    file_id         VARCHAR(36)    NOT NULL,   -- UUIDv4 from header
    source_pubkey   VARCHAR(44)    NOT NULL,   -- base64 Ed25519 pubkey
    account_id      INT UNSIGNED   NOT NULL,   -- target account
    character_id    INT UNSIGNED   NOT NULL,   -- newly created character
    imported_at     DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (file_id, source_pubkey),
    INDEX idx_account (account_id)
);
```

## License

MIT — see [LICENSE](LICENSE).
