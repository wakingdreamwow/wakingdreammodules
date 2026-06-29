# Wakingdream Modules

Custom AzerothCore 3.3.5a modules powering the **Wakingdream** WoW private server.

## Modules

| Module | Purpose |
|---|---|
| `mod-emerald-dream` | Hyjal Smaragdtraum hub (Ysera + 4 Vanilla Dragons + Nightmare Lord + S1-S5 sub-zones); HyjalDragonRewards adds +50 AT per dragon kill |
| `mod-event-loot` | World boss event engine — multi-boss tracking, level/class-aware loot picker, immersive helper-bot waves (Auto-Raid + role-balanced) |
| `mod-raidfill` | `.raidfill [size]` command + Raid-Organizer NPC at each PvE raid entrance; fills the party with level-matched, faction-matched, role/class-capped bots |
| `mod-starter-kit` | One-time login grant (5g + 4× Small Brown Pouch) per character; bots included |
| `mod-idle-farming` | Offline gathering: logout timestamps → next login mails skill-scaled profession mats (mining/herbalism/skinning/fishing) |
| `mod-duel-honor` | Honor reward on `DUEL_WON` against level-matched real players; per-victim cooldown anti-farm |
| `mod-fly-in-old-world` | Server-side `SetCanFly(true)` for players with riding skill on Map 0/1; bypasses Northrend `HasSpell(54197)` Cold-Weather-Flying check via auto-grant |

## Convention

- Each module follows the AzerothCore module layout: `src/`, `conf/`, `data/sql/`, optional `include.sh`
- All custom content is **English** (matches the enUS-locale client patches)
- All custom DB rows live as **idempotent SQL** (DELETE+INSERT) in `<module>/data/sql/db-world/base/` — applied automatically by the AC DB updater on worldserver boot (requires `AC_UPDATES_ENABLE_DATABASES=7`)
- Entry-ID conventions: 990000-range for custom NPCs/items/spawns/quests; guid blocks start at 5300000+

## Build

These modules drop into an AzerothCore source tree at `azerothcore-wotlk/modules/<name>/`. The worldserver auto-discovers via `include.sh` (when present) and links the static-script loader.

```bash
cd azerothcore-wotlk
# place this repo's folders under modules/ (e.g. as a git submodule, or rsync)
docker compose build ac-worldserver
docker compose up -d ac-worldserver
```

## Server reference

Live deployment: see `projects/wow-server/PLAN.md` in the agent workspace for the full operational story (Netcup VPS, FCMS frontend, donate pipeline, anti-cheat, world-boss roster, etc.).

## License

GPL-2.0 (matches AzerothCore upstream).
