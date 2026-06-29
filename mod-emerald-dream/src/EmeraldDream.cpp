/* mod-emerald-dream: portal warden NPC -> in/out of the Emerald Dream.
 * Hub relocated to Mount Hyjal / Nordrassil (map 1) because map 169 has no terrain
 * (players & creatures fall through). Entrance is the canonical Twilight Grove (Duskwood). */
#include "ScriptMgr.h"
#include "Player.h"
#include "Creature.h"
#include "ScriptedGossip.h"
#include "Config.h"
#include "Chat.h"

enum { ACT_ENTER = 1, ACT_LEAVE = 2 };

// Emerald Dream hub at Nordrassil (Hyjal, map 1) and the Twilight Grove exit (Duskwood, map 0).
static constexpr uint32 HUB_MAP = 1;
static constexpr float HUB_X = 5372.7f, HUB_Y = -3378.7f, HUB_Z = 1657.5f, HUB_O = 3.9f;
static constexpr float GROVE_X = -10428.8f, GROVE_Y = -392.2f, GROVE_Z = 44.1f, GROVE_O = 0.93f;

static bool InDream(Player* p)
{
    // "in the dream" = standing in the Hyjal hub area (map 1, near Nordrassil)
    return p->GetMapId() == HUB_MAP && p->GetExactDist2d(HUB_X, HUB_Y) < 800.0f;
}

class npc_dream_portal : public CreatureScript
{
public:
    npc_dream_portal() : CreatureScript("npc_dream_portal") { }

    bool OnGossipHello(Player* player, Creature* creature) override
    {
        uint32 minLvl = sConfigMgr->GetOption<uint32>("EmeraldDream.MinLevel", 80);
        if (InDream(player))
            AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Verlasse den Smaragdtraum.", GOSSIP_SENDER_MAIN, ACT_LEAVE);
        else if (player->GetLevel() < minLvl)
            ChatHandler(player->GetSession()).PSendSysMessage("Der Smaragdtraum wuerde dich verschlingen, Sterblicher. Kehre mit Stufe %u wieder.", minLvl);
        else
            AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Tritt in den Smaragdtraum ein.", GOSSIP_SENDER_MAIN, ACT_ENTER);
        SendGossipMenuFor(player, 1, creature->GetGUID());
        return true;
    }

    bool OnGossipSelect(Player* player, Creature* /*creature*/, uint32 /*sender*/, uint32 action) override
    {
        CloseGossipMenuFor(player);
        uint32 minLvl = sConfigMgr->GetOption<uint32>("EmeraldDream.MinLevel", 80);
        if (action == ACT_ENTER && player->GetLevel() >= minLvl)
            player->TeleportTo(HUB_MAP, HUB_X, HUB_Y, HUB_Z, HUB_O);
        else if (action == ACT_LEAVE)
            player->TeleportTo(0, GROVE_X, GROVE_Y, GROVE_Z, GROVE_O);
        return true;
    }
};

void AddEmeraldDreamScripts() { new npc_dream_portal(); }
