/*
 * mod-duel-honor: award honor for winning duels against opponents within a
 * level window. Anti-farm: lower-level bots give nothing, per-victim cooldown.
 */
#include "ScriptMgr.h"
#include "Player.h"
#include "Config.h"
#include "Chat.h"
#include "World.h"
#include "GameTime.h"
#include "SharedDefines.h"
#include "Playerbots.h"
#include <unordered_map>

namespace
{
    std::unordered_map<uint64, uint64> g_lastAward; // (winner<<32|loser) -> gametime
}

class DuelHonor : public PlayerScript
{
public:
    DuelHonor() : PlayerScript("DuelHonor", { PLAYERHOOK_ON_DUEL_END }) { }

    void OnPlayerDuelEnd(Player* winner, Player* loser, DuelCompleteType type) override
    {
        if (!sConfigMgr->GetOption<bool>("DuelHonor.Enable", true)) return;
        if (type != DUEL_WON) return;
        if (!winner || !loser || winner == loser) return;

        // Winner must be a real player; bots don't farm honor
        if (GET_PLAYERBOT_AI(winner)) return;

        bool onlyVsBots = sConfigMgr->GetOption<bool>("DuelHonor.OnlyVsBots", true);
        bool loserIsBot = GET_PLAYERBOT_AI(loser) != nullptr;
        if (onlyVsBots && !loserIsBot) return;

        int pl = (int)winner->GetLevel();
        int bl = (int)loser->GetLevel();
        int minBelow = (int)sConfigMgr->GetOption<uint32>("DuelHonor.MinBelow", 3);
        int maxAbove = (int)sConfigMgr->GetOption<uint32>("DuelHonor.MaxAbove", 5);
        int maxLvl = (int)sWorld->getIntConfig(CONFIG_MAX_PLAYER_LEVEL);

        bool eligible;
        if (pl >= maxLvl)
            eligible = (bl >= maxLvl);                     // at cap: only vs cap-level
        else
            eligible = (bl >= pl - minBelow) && (bl <= pl + maxAbove);

        if (!eligible)
        {
            ChatHandler(winner->GetSession()).PSendSysMessage("|cffff0000[Ehre]|r Gegner ausserhalb des Level-Fensters - keine Ehre.");
            return;
        }

        uint32 cd = sConfigMgr->GetOption<uint32>("DuelHonor.VictimCooldownSeconds", 300);
        if (cd > 0)
        {
            uint64 key = ((uint64)winner->GetGUID().GetCounter() << 32) | loser->GetGUID().GetCounter();
            uint64 now = (uint64)GameTime::GetGameTime().count();
            auto it = g_lastAward.find(key);
            if (it != g_lastAward.end() && it->second + cd > now)
            {
                ChatHandler(winner->GetSession()).PSendSysMessage("|cffffff00[Ehre]|r Diesen Gegner hast du zu kuerzlich besiegt - noch keine neue Ehre.");
                return;
            }
            g_lastAward[key] = now;
        }

        winner->RewardHonor(loser, 1, -1, false); // honor=-1 -> standard calc, no XP
        ChatHandler(winner->GetSession()).PSendSysMessage("|cff33ff99[Ehre]|r Sieg im Duell - Ehre erhalten!");
    }
};

void AddDuelHonorScripts()
{
    new DuelHonor();
}
