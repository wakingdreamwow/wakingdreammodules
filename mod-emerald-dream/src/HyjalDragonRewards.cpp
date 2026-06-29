/*
 * Hyjal Smaragd-Drachen Rewards
 *
 * On kill of 14887/14888/14889/14890:
 *  - +50 Activity Tokens (FCMS account_data.vp) for each player in killer's group
 *  - Announce ingame
 */

#include "ScriptMgr.h"
#include "Creature.h"
#include "Player.h"
#include "Group.h"
#include "DatabaseEnv.h"
#include "Chat.h"
#include "ScriptedCreature.h"

namespace
{
    bool IsHyjalDragon(uint32 entry)
    {
        return entry == 14887 || entry == 14888 || entry == 14889 || entry == 14890;
    }

    std::string DragonName(uint32 entry)
    {
        switch (entry)
        {
            case 14887: return "Ysondre";
            case 14888: return "Lethon";
            case 14889: return "Emeriss";
            case 14890: return "Taerar";
            default:    return "Smaragd-Drache";
        }
    }

    void RewardActivityTokens(Player* player, uint32 dragonEntry)
    {
        if (!player || !player->GetSession())
            return;

        uint32 accountId = player->GetSession()->GetAccountId();
        // FCMS account_data.id = acore_auth.account.id (1:1)
        LoginDatabase.Execute(
            "UPDATE fusioncms.account_data SET vp = vp + 50 WHERE id = {}",
            accountId);

        std::string msg = "|cff20ff20[Hyjal]|r You earned |cffffff0050 Activity Tokens|r for defeating " +
                          DragonName(dragonEntry) + ".";
        ChatHandler(player->GetSession()).SendSysMessage(msg);
    }
}

class hyjal_dragon_rewards : public CreatureScript
{
public:
    hyjal_dragon_rewards() : CreatureScript("hyjal_dragon_rewards") {}

    struct hyjal_dragon_rewardsAI : public ScriptedAI
    {
        hyjal_dragon_rewardsAI(Creature* c) : ScriptedAI(c) {}

        void JustDied(Unit* killer) override
        {
            uint32 entry = me->GetEntry();
            if (!IsHyjalDragon(entry))
                return;

            if (!killer)
                return;

            Player* playerKiller = killer->ToPlayer();
            Group* group = nullptr;
            if (playerKiller)
                group = playerKiller->GetGroup();

            if (group)
            {
                for (GroupReference* itr = group->GetFirstMember(); itr; itr = itr->next())
                {
                    Player* member = itr->GetSource();
                    if (member && member->IsInWorld() && member->GetSession())
                        RewardActivityTokens(member, entry);
                }
            }
            else if (playerKiller)
            {
                RewardActivityTokens(playerKiller, entry);
            }
        }
    };

    CreatureAI* GetAI(Creature* c) const override
    {
        return new hyjal_dragon_rewardsAI(c);
    }
};

void AddHyjalDragonRewardsScripts()
{
    new hyjal_dragon_rewards();
}
