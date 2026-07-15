# mod-character-portability — TrinityCore 3.3.5 preview port

**⚠️ Preview status.** This is a mechanical port of the AzerothCore
reference implementation
([`../mod-character-portability`](../mod-character-portability)) to
TrinityCore's `3.3.5` branch. The changes below are mechanical
(`LOG_INFO` → `TC_LOG_INFO`, `Acore::` → `Trinity::`, and the AC module
entry-point convention). **We do not run a TrinityCore build server**,
so the port has not been compile-tested against a live TC-3.3.5 tree.
The CI in this repo builds it against TC-3.3.5 HEAD headers-only; that
catches API drift but not runtime bugs.

If you're a TC-3.3.5 operator and adopt this: expect one build cycle to
shake out any remaining API delta, and please file an issue with the
compile output. We'll fold your fixes back so the next adopter starts
cleaner.

## What's different from the AC reference

| Change                                     | AC                   | TC-3.3.5             |
| ------------------------------------------ | -------------------- | -------------------- |
| Log macros                                 | `LOG_INFO(...)`      | `TC_LOG_INFO(...)`   |
| Chat-command namespace                     | `Acore::ChatCommands`| `Trinity::ChatCommands` |
| Module entry-point symbol                  | `Addmod_<name>Scripts()` | `AddSC_mod_<name>Scripts()` |
| JSON `"core"` string emitted in `.wcpx`    | `"AzerothCore"`      | `"TrinityCore"`      |
| Player/Item GUID generator                 | `sObjectMgr->GetGenerator<HighGuid::Player>().Generate()` | same |
| `sCharacterCache->AddCharacterCacheEntry` | present              | present              |
| `SPELL_AURA_MOUNTED` / SpellInfo           | same                 | same                 |

## Install (TrinityCore layout)

TrinityCore doesn't have a formal "modules" tree the way AC does; drop
the source files into a subdirectory of `src/server/scripts/` and
register the entry-point in `src/server/scripts/ScriptLoader.cpp`:

```bash
cp -r src/ /path/to/TrinityCore/src/server/scripts/Custom/mod-character-portability/
```

In `src/server/scripts/ScriptLoader.cpp` add:
```cpp
void AddSC_mod_character_portabilityScripts();
// ... inside AddScripts() ...
AddSC_mod_character_portabilityScripts();
```

In `src/server/scripts/CMakeLists.txt` add the new folder to the source
glob (TC uses `CollectSourceFiles`; standard scripts tree pattern).

Install `libargon2` (Ubuntu: `apt-get install libargon2-dev`) and add
it to the worldserver's linker line via
`target_link_libraries(worldserver PRIVATE argon2)` in
`src/server/worldserver/CMakeLists.txt`.

## Config

Copy `conf/character_portability.conf.dist` to
`env/dist/etc/modules/` (path may vary — anywhere `sConfigMgr` scans).
Same schema as the AC reference; see the AC README for field-by-field
explanations.

## SQL schema

Run `data/sql/*.sql` against your `characters` database. Both cores use
the WotLK 3.3.5 characters schema, so the migrations are identical to
the AC version.

## Known TC-3.3.5 differences we couldn't verify

Because we don't build against TC, these might still bite:

1. **`sConfigMgr->GetOption<T>` templated signature** — recent TC
   supports it; older TC-3.3.5 forks may only have
   `sConfigMgr->GetStringDefault`/`GetIntDefault`. If you hit this,
   patch `CharacterPortability_Config.cpp` accordingly.
2. **`CharacterDatabase.Query()` bind style** — same on both cores as
   of 2026, but if you're on a TC fork more than 2y old check the
   `Field::Get<T>()` API.
3. **Character save flow** — we insert into `characters` directly and
   let `sCharacterCache->AddCharacterCacheEntry` register the row.
   Recent TC accepts this; if you get a "character not visible in
   character list" error, force a `sCharacterCache->UpdateCharacter…`
   call after insert.

## Feedback

- Bug reports: https://github.com/wakingdreamwow/wakingdreammodules/issues
- Fold-back patches: PR against this repo's `main`. If you produce
  a delta that also works on AC, we'll merge it as-is; otherwise it
  goes into the TC-335 subtree only.
