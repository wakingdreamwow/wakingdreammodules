/*
 * mod-starter-kit: new characters (and bots) receive a one-time starter kit on login:
 * configurable gold + simple bags. Bags are auto-equipped into empty bag slots so bots
 * actually use them; any leftover bags go into the backpack. One-time per character,
 * tracked in `character_starterkit`.
 */
#include "ScriptMgr.h"
#include "Player.h"
#include "Config.h"
#include "Chat.h"
#include "Item.h"
#include "DatabaseEnv.h"
#include "Playerbots.h"

class StarterKit : public PlayerScript
{
public:
    StarterKit() : PlayerScript("StarterKit", { PLAYERHOOK_ON_LOGIN }) { }

    void OnPlayerLogin(Player* player) override
    {
        if (!player)
            return;

        if (!sConfigMgr->GetOption<bool>("StarterKit.Enable", true))
            return;

        bool isBot = GET_PLAYERBOT_AI(player) != nullptr;
        if (isBot && !sConfigMgr->GetOption<bool>("StarterKit.IncludeBots", true))
            return;

        ObjectGuid::LowType guid = player->GetGUID().GetCounter();

        // one-time guard
        if (CharacterDatabase.Query("SELECT 1 FROM character_starterkit WHERE guid = {}", guid))
            return;

        uint32 gold     = sConfigMgr->GetOption<uint32>("StarterKit.Gold", 5);
        uint32 bagEntry = sConfigMgr->GetOption<uint32>("StarterKit.BagEntry", 4496); // Small Brown Pouch (6 slots)
        uint32 bagCount = sConfigMgr->GetOption<uint32>("StarterKit.BagCount", 4);

        if (gold > 0)
            player->ModifyMoney(int32(gold) * GOLD);

        // equip bags into empty bag slots first, remainder into the backpack
        uint32 given = 0;
        for (uint8 slot = INVENTORY_SLOT_BAG_START; slot < INVENTORY_SLOT_BAG_END && given < bagCount; ++slot)
        {
            if (player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
                continue; // slot already holds a bag

            uint16 dest;
            if (player->CanEquipNewItem(slot, dest, bagEntry, false) == EQUIP_ERR_OK)
                if (player->EquipNewItem(dest, bagEntry, true))
                    ++given;
        }
        for (; given < bagCount; ++given)
            player->AddItem(bagEntry, 1);

        player->SaveToDB(false, false);
        CharacterDatabase.Execute("INSERT INTO character_starterkit (guid) VALUES ({})", guid);

        if (!isBot && player->GetSession())
            ChatHandler(player->GetSession()).PSendSysMessage("Welcome! Starter kit delivered: gold and bags. Have fun out there!");
    }
};

void AddStarterKit()
{
    new StarterKit();
}
