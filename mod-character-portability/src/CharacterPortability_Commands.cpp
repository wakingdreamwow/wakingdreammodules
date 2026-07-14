/*
 * WCPX GM chat commands.
 *
 *   .wcpx export <charname> <passphrase>
 *   .wcpx import <path> <passphrase> <target_account>
 *   .wcpx trust list
 *   .wcpx trust approve <pubkey>
 */
#include "CharacterPortability.h"

#include "Chat.h"
#include "ChatCommand.h"
#include "ObjectMgr.h"
#include "AccountMgr.h"
#include "DatabaseEnv.h"

using namespace Acore::ChatCommands;

namespace WCPX
{
    class wcpx_commandscript : public CommandScript
    {
    public:
        wcpx_commandscript() : CommandScript("wcpx_commandscript") {}

        ChatCommandTable GetCommands() const override
        {
            static ChatCommandTable trustSub =
            {
                { "list",    HandleTrustList,    SEC_ADMINISTRATOR, Console::Yes },
                { "approve", HandleTrustApprove, SEC_ADMINISTRATOR, Console::Yes },
            };
            static ChatCommandTable rootSub =
            {
                { "export", HandleExport, SEC_ADMINISTRATOR, Console::Yes },
                { "import", HandleImport, SEC_ADMINISTRATOR, Console::Yes },
                { "trust",  trustSub },
            };
            static ChatCommandTable root =
            {
                { "wcpx", rootSub },
            };
            return root;
        }

        static bool HandleExport(ChatHandler* handler, std::string const& charName,
                                 std::string const& passphrase)
        {
            uint32_t guid = sObjectMgr->GetPlayerGUIDByName(charName).GetCounter();
            if (!guid)
            {
                handler->PSendSysMessage("[WCPX] unknown character: %s", charName.c_str());
                return true;
            }
            ExportRequest req;
            req.characterGuid = guid;
            req.passphrase = passphrase;
            req.bypassRateLimit = true;
            auto res = DoExport(req);
            if (!res.ok)
            {
                handler->PSendSysMessage("[WCPX] export failed: %s", res.errorMessage.c_str());
                return true;
            }
            handler->PSendSysMessage("[WCPX] exported to %s (file_id=%s)",
                                    res.filePath.c_str(), res.fileId.c_str());
            return true;
        }

        static bool HandleImport(ChatHandler* handler, std::string const& path,
                                 std::string const& passphrase, uint32_t accountId)
        {
            if (!sAccountMgr->GetName(accountId).length())
            {
                handler->PSendSysMessage("[WCPX] unknown target account %u", accountId);
                return true;
            }
            ImportRequest req;
            req.filePath = path;
            req.passphrase = passphrase;
            req.targetAccountId = accountId;
            req.bypassPaidToken = true;
            auto res = DoImport(req);
            if (!res.ok)
            {
                handler->PSendSysMessage("[WCPX] import failed: %s", res.errorMessage.c_str());
                return true;
            }
            handler->PSendSysMessage("[WCPX] imported as character guid=%u",
                                    res.newCharacterGuid);
            return true;
        }

        static bool HandleTrustList(ChatHandler* handler)
        {
            QueryResult r = CharacterDatabase.Query(
                "SELECT source_pubkey, source_name, source_core, seen_count, first_seen "
                "FROM wcpx_pending_pubkeys ORDER BY first_seen DESC");
            if (!r) { handler->SendSysMessage("[WCPX] no pending pubkeys"); return true; }
            handler->SendSysMessage("[WCPX] pending pubkeys:");
            do
            {
                auto row = r->Fetch();
                handler->PSendSysMessage(" %s | %s (%s) seen=%u first=%s",
                    row[0].Get<std::string>().c_str(),
                    row[1].Get<std::string>().c_str(),
                    row[2].Get<std::string>().c_str(),
                    row[3].Get<uint32_t>(),
                    row[4].Get<std::string>().c_str());
            } while (r->NextRow());
            return true;
        }

        static bool HandleTrustApprove(ChatHandler* handler, std::string const& pubkey)
        {
            handler->PSendSysMessage("[WCPX] appending pubkey to whitelist: %s", pubkey.c_str());
            handler->PSendSysMessage(
                "[WCPX] NOTE: add this pubkey to CharacterPortability.Trust.Whitelist in "
                "character_portability.conf and reload the config for persistence.");
            Config::Instance().TrustWhitelist.push_back(pubkey);
            CharacterDatabase.Execute(
                "DELETE FROM wcpx_pending_pubkeys WHERE source_pubkey='{}'", pubkey);
            return true;
        }
    };

    void RegisterChatCommands()
    {
        new wcpx_commandscript();
    }
}
