/*
 * WCPX GM chat commands.
 *
 *   .wcpx export <charname> <passphrase>
 *   .wcpx import <path> <passphrase> <target_account>
 *   .wcpx trust list
 *   .wcpx trust approve <pubkey>
 */
#include "CharacterPortability.h"

#include "Log.h"
#include "ScriptMgr.h"
#include "Chat.h"
#include "ChatCommand.h"
#include "ObjectMgr.h"
#include "AccountMgr.h"
#include "CharacterCache.h"
#include "DatabaseEnv.h"
#include "RBAC.h"

using namespace Trinity::ChatCommands;

namespace WCPX
{
    class wcpx_commandscript : public CommandScript
    {
    public:
        wcpx_commandscript() : CommandScript("wcpx_commandscript") {}

        ChatCommandTable GetCommands() const override
        {
            // TC-3.3.5 requires an rbac::RBACPermissions constant instead of AC's
            // SEC_ADMINISTRATOR. We reuse RBAC_PERM_COMMAND_RELOAD (607) as an
            // admin-level placeholder — adopters who want finer granularity can
            // extend TC's RBAC.h with dedicated WCPX_* permissions.
            static ChatCommandTable trustSub =
            {
                { "list",    HandleTrustList,    rbac::RBAC_PERM_COMMAND_RELOAD, Console::Yes },
                { "approve", HandleTrustApprove, rbac::RBAC_PERM_COMMAND_RELOAD, Console::Yes },
            };
            static ChatCommandTable rootSub =
            {
                { "export", HandleExport, rbac::RBAC_PERM_COMMAND_RELOAD, Console::Yes },
                { "import", HandleImport, rbac::RBAC_PERM_COMMAND_RELOAD, Console::Yes },
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
            uint32_t guid = sCharacterCache->GetCharacterGuidByName(charName).GetCounter();
            if (!guid)
            {
                handler->SendSysMessage(("[WCPX] unknown character: " + charName).c_str());
                return true;
            }
            ExportRequest req;
            req.characterGuid = guid;
            req.passphrase = passphrase;
            req.bypassRateLimit = true;
            auto res = DoExport(req);
            if (!res.ok)
            {
                TC_LOG_ERROR("module", "[WCPX] export failed for {}: {}", charName, res.errorMessage);
                handler->SendSysMessage(("[WCPX] export failed: " + res.errorMessage).c_str());
                return true;
            }
            handler->SendSysMessage(
                ("[WCPX] exported to " + res.filePath + " (file_id=" + res.fileId + ")").c_str());
            return true;
        }

        static bool HandleImport(ChatHandler* handler, std::string const& path,
                                 std::string const& passphrase, uint32_t accountId)
        {
            std::string accountName;
            if (!sAccountMgr->GetName(accountId, accountName) || accountName.empty())
            {
                handler->SendSysMessage(("[WCPX] unknown target account " + std::to_string(accountId)).c_str());
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
                TC_LOG_ERROR("module", "[WCPX] import failed: {}", res.errorMessage);
                handler->SendSysMessage(("[WCPX] import failed: " + res.errorMessage).c_str());
                return true;
            }
            handler->SendSysMessage(
                ("[WCPX] imported as character guid=" + std::to_string(res.newCharacterGuid)).c_str());
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
                std::ostringstream line;
                line << " " << row[0].GetString()
                     << " | " << row[1].GetString()
                     << " (" << row[2].GetString() << ")"
                     << " seen=" << row[3].GetUInt32()
                     << " first=" << row[4].GetString();
                handler->SendSysMessage(line.str().c_str());
            } while (r->NextRow());
            return true;
        }

        static bool HandleTrustApprove(ChatHandler* handler, std::string const& pubkey)
        {
            handler->SendSysMessage(("[WCPX] appending pubkey to whitelist: " + pubkey).c_str());
            handler->SendSysMessage(
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
