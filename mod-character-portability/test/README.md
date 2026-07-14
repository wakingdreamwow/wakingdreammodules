# Standalone smoke test

Tests the crypto + codec layers of the mod without needing a full AzerothCore
build. Verifies:

- Canonical JSON (sorted keys, no whitespace)
- Binary file roundtrip (write .wcpx → read .wcpx)
- AES-256-GCM encrypt/decrypt roundtrip + tamper-detect
- Argon2id KDF determinism
- Ed25519 sign/verify + tamper-detect
- Base64 encode/decode roundtrip

Does NOT test the DB-touching bits (Export/Import) — those need AC.

## Requirements

```bash
sudo apt install libssl-dev libargon2-dev
```

Headers only — the runtime shared libs (`libssl.so`, `libargon2.so.1`) come
with a standard AC deployment already.

## Build + run

```bash
cd test/
make run
```

Expected: 10 tests, 0 failed.

If you skip the install step, `make` will fail with `openssl/evp.h: No such
file or directory` — install the dev packages and retry.
