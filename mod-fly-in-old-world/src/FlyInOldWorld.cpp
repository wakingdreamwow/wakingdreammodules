/*
 * mod-fly-in-old-world (customized): fly everywhere in the old world (maps 0/1) once normal
 * flying is learned — WITHOUT GM rights and WITHOUT a client patch.
 *
 * Why server-side SetCanFly: the 3.3.5 client hardcodes flying mounts to Outland (530) and
 * Northrend (571). On maps 0/1 the client refuses to let a mount take off, no matter what the
 * server's CanFlyInZone hook says. The ONLY thing that overrides the client is the forced
 * fly flag — exactly what ".gm fly on" does (Unit::SetCanFly). So we replicate that for any
 * non-GM player who has learned flying, scoped to the old world.
 */
#include "ScriptMgr.h"
#include "Player.h"
#include "SpellInfo.h"
#include "Playerbots.h"

enum FlyInOldWorldSpells
{
    SPELL_EXPERT_RIDING  = 34090, // 150% flying (normal flying)
    SPELL_ARTISAN_RIDING = 34091, // 280% flying (fast, bought in-game)
    SPELL_COLD_WEATHER   = 54197  // Northrend flying access
};

class FlyInOldWorld : public PlayerScript
{
public:
    FlyInOldWorld() : PlayerScript("FlyInOldWorld",
        { PLAYERHOOK_ON_CAN_PLAYER_FLY_IN_ZONE, PLAYERHOOK_ON_LOGIN, PLAYERHOOK_ON_UPDATE_ZONE }) { }

    static bool KnowsFlying(Player* player)
    {
        return player->HasSpell(SPELL_EXPERT_RIDING) || player->HasSpell(SPELL_ARTISAN_RIDING);
    }

    // Forced fly flag (like ".gm fly on"), scoped to the old world. Skips bots and GMs (GMs use .gm fly).
    static void ApplyOldWorldFly(Player* player)
    {
        if (!player || GET_PLAYERBOT_AI(player) || player->IsGameMaster())
            return;

        uint32 m = player->GetMapId();
        if (m == 0 || m == 1) // Eastern Kingdoms / Kalimdor (old world)
            player->SetCanFly(KnowsFlying(player));
        else if (m != 530 && m != 571) // leave Outland/Northrend to the core's normal flight
            player->SetCanFly(false);  // strip forced fly inside instances/BGs
    }

    bool OnPlayerCanFlyInZone(Player* player, uint32 mapId, uint32 zoneId, SpellInfo const* /*bySpell*/) override
    {
        uint32 v_map = GetVirtualMapForMapAndZone(mapId, zoneId);
        if (v_map == 0 || v_map == 1) // old world
            return KnowsFlying(player);
        return true; // Outland / Northrend handled by core (Cold Weather Flying)
    }

    void OnPlayerLogin(Player* player) override
    {
        if (!player || GET_PLAYERBOT_AI(player)) // skip bots
            return;
        // Once flying is learned, also grant Northrend access so flight works everywhere.
        if (KnowsFlying(player) && !player->HasSpell(SPELL_COLD_WEATHER))
            player->learnSpell(SPELL_COLD_WEATHER);
        ApplyOldWorldFly(player);
    }

    void OnPlayerUpdateZone(Player* player, uint32 /*newZone*/, uint32 /*newArea*/) override
    {
        ApplyOldWorldFly(player);
    }
};

void AddFlyInOldWorld()
{
    new FlyInOldWorld();
}
