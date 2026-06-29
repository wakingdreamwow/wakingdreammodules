#include "Chat.h"
#include "CommandScript.h"
#include "Creature.h"
#include "Player.h"
#include "Group.h"
#include "GroupMgr.h"
#include "ScriptMgr.h"
#include "ScriptedGossip.h"
#include "Configuration/Config.h"
#include "Random.h"
#include "Playerbots.h"
#include "RandomPlayerbotMgr.h"
#include "PlayerbotAI.h"
#include <cmath>
#include <vector>
#include <algorithm>

using namespace Acore::ChatCommands;

enum RFRole { RF_TANK = 0, RF_HEAL = 1, RF_DPS = 2 };

static RFRole RoleOf(Player* p)
{
    if (PlayerbotAI::IsTank(p, true)) return RF_TANK;
    if (PlayerbotAI::IsHeal(p, true)) return RF_HEAL;
    return RF_DPS;
}

static void TeleNearLeader(Player* bot, Player* leader)
{
    float ang = frand(0.f, 6.2831f), dist = frand(2.f, 5.f);
    bot->TeleportTo(leader->GetMapId(),
        leader->GetPositionX() + std::cos(ang) * dist,
        leader->GetPositionY() + std::sin(ang) * dist,
        leader->GetPositionZ(), ang);
}

// Role-aware, class-capped fill. Counts current members and fills the gaps.
static uint32 RaidFill_Do(Player* leader, uint32 target)
{
    if (!leader) return 0;
    uint32 maxCap = sConfigMgr->GetOption<uint32>("RaidFill.MaxSize", 40);
    if (target < 2) target = 2;
    if (target > maxCap) target = maxCap;
    if (target > 40) target = 40;

    Group* grp = leader->GetGroup();
    if (grp && grp->GetLeaderGUID() != leader->GetGUID())
        return 0;
    if (!grp)
    {
        grp = new Group();
        if (!grp->Create(leader)) { delete grp; return 0; }
        sGroupMgr->AddGroup(grp);
    }
    if (target > 5 && !grp->isRaidGroup())
        grp->ConvertToRaid();

    // Role targets + per-class cap by raid size
    int needT, needH, classCap;
    if (target <= 5)       { needT = 1; needH = 1; classCap = (int)sConfigMgr->GetOption<uint32>("RaidFill.ClassCap5", 2); }
    else if (target <= 10) { needT = 2; needH = 3; classCap = (int)sConfigMgr->GetOption<uint32>("RaidFill.ClassCap10", 2); }
    else if (target <= 25) { needT = 3; needH = 6; classCap = (int)sConfigMgr->GetOption<uint32>("RaidFill.ClassCap25", 5); }
    else                   { needT = 4; needH = 9; classCap = (int)sConfigMgr->GetOption<uint32>("RaidFill.ClassCap40", 8); }
    int needD = (int)target - needT - needH;
    if (needD < 0) needD = 0;

    // Count current members by role and class
    int curT = 0, curH = 0, curD = 0;
    int classCount[12] = { 0 };
    for (GroupReference* ref = grp->GetFirstMember(); ref; ref = ref->next())
    {
        Player* m = ref->GetSource(); if (!m) continue;
        uint8 c = m->getClass(); if (c < 12) classCount[c]++;
        switch (RoleOf(m)) { case RF_TANK: curT++; break; case RF_HEAL: curH++; break; default: curD++; }
    }
    int wantT = std::max(0, needT - curT);
    int wantH = std::max(0, needH - curH);
    int wantD = std::max(0, needD - curD);

    TeamId team = leader->GetTeamId();
    int plvl = (int)leader->GetLevel();
    int below = (int)sConfigMgr->GetOption<uint32>("RaidFill.LevelBelow", 0);
    int above = (int)sConfigMgr->GetOption<uint32>("RaidFill.LevelAbove", 0);
    int loLvl = plvl - below, hiLvl = plvl + above;
    uint32 added = 0;

    for (int pass = 0; pass < 3; ++pass)
    {
        int* want = pass == 0 ? &wantT : (pass == 1 ? &wantH : &wantD);
        RFRole role = pass == 0 ? RF_TANK : (pass == 1 ? RF_HEAL : RF_DPS);
        if (*want <= 0) continue;
        for (auto const& it : sRandomPlayerbotMgr.GetAllBots())
        {
            if (*want <= 0 || grp->IsFull() || grp->GetMembersCount() >= target) break;
            Player* bot = it.second;
            if (!bot || !bot->IsInWorld() || !bot->IsAlive() || bot->IsInCombat() || bot->GetGroup()) continue;
            if (bot->GetTeamId() != team) continue;
            int lvl = (int)bot->GetLevel(); if (lvl < loLvl || lvl > hiLvl) continue;
            uint8 c = bot->getClass(); if (c >= 12 || classCount[c] >= classCap) continue;
            if (RoleOf(bot) != role) continue;
            if (grp->AddMember(bot))
            {
                if (PlayerbotAI* ai = GET_PLAYERBOT_AI(bot)) { ai->SetMaster(leader); ai->ResetStrategies(); }
                TeleNearLeader(bot, leader);
                classCount[c]++; (*want)--; ++added;
            }
        }
    }
    return added;
}

class raidfill_commandscript : public CommandScript
{
public:
    raidfill_commandscript() : CommandScript("raidfill_commandscript") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable tbl =
        {
            { "raidfill", HandleRaidFillCommand, SEC_PLAYER, Console::No },
        };
        return tbl;
    }

    static bool HandleRaidFillCommand(ChatHandler* handler, Optional<uint32> sizeArg)
    {
        if (!sConfigMgr->GetOption<bool>("RaidFill.Enable", true))
            return true;
        Player* leader = handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
        if (!leader) return false;
        if (leader->IsInCombat()) { handler->PSendSysMessage("RaidFill: not possible in combat."); return true; }
        uint32 target = sizeArg ? *sizeArg : sConfigMgr->GetOption<uint32>("RaidFill.DefaultSize", 25);
        uint32 added = RaidFill_Do(leader, target);
        Group* grp = leader->GetGroup();
        handler->PSendSysMessage("RaidFill: {} bots added. Group now {}.", added, grp ? grp->GetMembersCount() : 1);
        return true;
    }
};

class npc_raid_commander : public CreatureScript
{
public:
    npc_raid_commander() : CreatureScript("npc_raid_commander") { }

    bool OnGossipHello(Player* player, Creature* creature) override
    {
        if (sConfigMgr->GetOption<bool>("RaidFill.Enable", true))
        {
            AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Fill raid to 25", GOSSIP_SENDER_MAIN, 25);
            AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Fill raid to 10", GOSSIP_SENDER_MAIN, 10);
            AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Fill group to 5 (dungeon)", GOSSIP_SENDER_MAIN, 5);
        }
        SendGossipMenuFor(player, 1, creature->GetGUID());
        return true;
    }

    bool OnGossipSelect(Player* player, Creature* /*creature*/, uint32 /*sender*/, uint32 action) override
    {
        ClearGossipMenuFor(player);
        CloseGossipMenuFor(player);
        if (!sConfigMgr->GetOption<bool>("RaidFill.Enable", true))
            return true;
        if (player->IsInCombat())
        {
            ChatHandler(player->GetSession()).PSendSysMessage("RaidFill: not possible in combat.");
            return true;
        }
        uint32 added = RaidFill_Do(player, action);
        ChatHandler(player->GetSession()).PSendSysMessage("RaidFill: {} bots added.", added);
        return true;
    }
};

class raidfill_playerscript : public PlayerScript
{
public:
    raidfill_playerscript() : PlayerScript("raidfill_playerscript", { PLAYERHOOK_ON_LOGOUT, PLAYERHOOK_ON_MAP_CHANGED }) { }

    void OnPlayerMapChanged(Player* player) override
    {
        if (!player || GET_PLAYERBOT_AI(player)) return;
        Group* grp = player->GetGroup();
        if (!grp || grp->GetLeaderGUID() != player->GetGUID()) return;
        for (GroupReference* ref = grp->GetFirstMember(); ref; ref = ref->next())
        {
            Player* m = ref->GetSource();
            if (!m || m == player) continue;
            PlayerbotAI* ai = GET_PLAYERBOT_AI(m);
            if (!ai || ai->GetMaster() != player) continue;
            if (!m->IsAlive()) continue;
            if (m->GetMapId() == player->GetMapId() && m->IsWithinDist(player, 60.0f)) continue;
            TeleNearLeader(m, player);
        }
    }

    void OnPlayerLogout(Player* player) override
    {
        Group* grp = player->GetGroup();
        if (!grp) return;
        std::vector<ObjectGuid> toRemove;
        for (GroupReference* ref = grp->GetFirstMember(); ref; ref = ref->next())
        {
            Player* m = ref->GetSource();
            if (!m || m == player) continue;
            if (PlayerbotAI* ai = GET_PLAYERBOT_AI(m))
                if (ai->GetMaster() == player) toRemove.push_back(m->GetGUID());
        }
        for (ObjectGuid g : toRemove)
        {
            if (Player* b = ObjectAccessor::FindPlayer(g))
                if (PlayerbotAI* ai = GET_PLAYERBOT_AI(b)) { ai->SetMaster(nullptr); ai->ResetStrategies(); }
            grp->RemoveMember(g);
        }
    }
};

void Addmod_raidfillScripts()
{
    new raidfill_commandscript();
    new npc_raid_commander();
    new raidfill_playerscript();
}
