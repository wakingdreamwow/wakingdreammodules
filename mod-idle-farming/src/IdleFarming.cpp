#include "ScriptMgr.h"
#include "Player.h"
#include "Config.h"
#include "Chat.h"
#include "Mail.h"
#include "Item.h"
#include "DatabaseEnv.h"
#include "GameTime.h"
#include "Playerbots.h"
#include <vector>
#include <string>
#include <utility>

namespace
{
    struct GatherTier { uint32 minSkill; uint32 itemId; char const* name; };
    struct Profession { uint32 skillId; char const* label; std::vector<GatherTier> tiers; };

    std::vector<Profession> const& GetProfessions()
    {
        static const std::vector<Profession> profs = {
            { SKILL_MINING, "Bergbau", {
                {1, 2770, "Kupfererz"}, {65, 2771, "Zinnerz"}, {125, 2772, "Eisenerz"},
                {175, 3858, "Mithrilerz"}, {230, 10620, "Thoriumerz"}, {275, 23424, "Feleisenerz"},
                {325, 36909, "Kobalterz"} } },
            { SKILL_HERBALISM, "Kraeuterkunde", {
                {1, 765, "Silberblatt"}, {70, 2447, "Friedensblume"}, {115, 3357, "Wilddornrose"},
                {160, 3818, "Fadenbluete"}, {210, 8838, "Sonnengras"}, {260, 13463, "Traumblatt"},
                {300, 22785, "Teufelskraut"}, {325, 36901, "Goldklee"} } },
            { SKILL_SKINNING, "Kuerschnerei", {
                {1, 2318, "Leichtes Leder"}, {100, 2319, "Mittleres Leder"}, {150, 4234, "Schweres Leder"},
                {200, 4304, "Dickes Leder"}, {250, 8170, "Robustes Leder"}, {300, 21887, "Knochenhautleder"},
                {325, 33568, "Borenleder"} } },
            { SKILL_FISHING, "Angeln", {
                {1, 6303, "Roher Brillenfisch"}, {100, 6308, "Roher Sumpfwels"},
                {200, 13422, "Roher Stachelschwanzaal"}, {300, 41808, "Knochenschuppenschnapper"} } },
        };
        return profs;
    }

    bool g_tableReady = false;
    void EnsureTable()
    {
        if (g_tableReady) return;
        CharacterDatabase.DirectExecute("CREATE TABLE IF NOT EXISTS `character_idle_farming` "
            "(`guid` INT UNSIGNED NOT NULL PRIMARY KEY, `logout_time` BIGINT NOT NULL) "
            "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
        g_tableReady = true;
    }
}

class IdleFarmingPlayerScript : public PlayerScript
{
public:
    IdleFarmingPlayerScript() : PlayerScript("IdleFarmingPlayerScript", { PLAYERHOOK_ON_LOGIN, PLAYERHOOK_ON_LOGOUT }) { }

    void OnPlayerLogout(Player* player) override
    {
        if (!sConfigMgr->GetOption<bool>("IdleFarming.Enable", true)) return;
        if (!player || GET_PLAYERBOT_AI(player)) return; // skip bots
        EnsureTable();
        CharacterDatabase.Execute("REPLACE INTO `character_idle_farming` (`guid`,`logout_time`) VALUES ({}, {})",
            player->GetGUID().GetCounter(), (uint64)GameTime::GetGameTime().count());
    }

    void OnPlayerLogin(Player* player) override
    {
        if (!sConfigMgr->GetOption<bool>("IdleFarming.Enable", true)) return;
        if (!player || GET_PLAYERBOT_AI(player)) return; // skip bots
        EnsureTable();

        uint32 guid = player->GetGUID().GetCounter();
        QueryResult res = CharacterDatabase.Query("SELECT `logout_time` FROM `character_idle_farming` WHERE `guid` = {}", guid);
        if (!res) return;
        uint64 logoutTime = (*res)[0].Get<uint64>();
        CharacterDatabase.Execute("DELETE FROM `character_idle_farming` WHERE `guid` = {}", guid);

        uint64 now = (uint64)GameTime::GetGameTime().count();
        if (now <= logoutTime) return;
        uint64 offlineSec = now - logoutTime;

        uint32 minMinutes = sConfigMgr->GetOption<uint32>("IdleFarming.MinOfflineMinutes", 30);
        if (offlineSec < (uint64)minMinutes * 60) return;

        uint32 maxHours = sConfigMgr->GetOption<uint32>("IdleFarming.MaxHours", 24);
        uint32 perHour  = sConfigMgr->GetOption<uint32>("IdleFarming.ItemsPerHour", 2);
        uint32 hours = (uint32)(offlineSec / 3600);
        if (hours > maxHours) hours = maxHours;
        if (hours == 0 || perHour == 0) return;

        std::vector<std::pair<uint32, uint32>> rewards;
        std::string body = "Waehrend deiner Abwesenheit (" + std::to_string(hours) +
                           " Std. angerechnet) haben deine Berufe weitergearbeitet:\n\n";
        bool any = false;

        for (Profession const& prof : GetProfessions())
        {
            if (!player->HasSkill(prof.skillId)) continue;
            uint32 skill = player->GetSkillValue(prof.skillId);
            if (skill == 0) continue;
            GatherTier const* chosen = nullptr;
            for (GatherTier const& t : prof.tiers)
                if (skill >= t.minSkill) chosen = &t;
            if (!chosen) continue;
            uint32 count = hours * perHour;
            if (count == 0) continue;
            if (count > 200) count = 200;
            rewards.emplace_back(chosen->itemId, count);
            body += "- " + std::string(prof.label) + ": " + std::to_string(count) + "x " + std::string(chosen->name) + "\n";
            any = true;
        }
        if (!any) return;

        CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();
        MailDraft draft("Ertraege deiner Abwesenheit", body);
        for (auto const& r : rewards)
            if (Item* item = Item::CreateItem(r.first, r.second, player))
            {
                item->SaveToDB(trans);
                draft.AddItem(item);
            }
        draft.SendMailTo(trans, MailReceiver(player), MailSender(MAIL_NORMAL, guid, MAIL_STATIONERY_GM));
        CharacterDatabase.CommitTransaction(trans);

        ChatHandler(player->GetSession()).PSendSysMessage("|cff33ff99[Idle-Farming]|r Deine Berufe haben offline gearbeitet - schau in deinen Briefkasten!");
    }
};

void AddIdleFarmingScripts()
{
    new IdleFarmingPlayerScript();
}
