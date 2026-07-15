#include "CharacterPortability.h"
#include "Config.h"
#include "Log.h"
#include <sstream>

// TC-3.3.5 exposes typed defaults via non-template GetStringDefault / GetIntDefault
// / GetBoolDefault. AC's templated `sConfigMgr->GetOption<T>(...)` does not exist.
// We use the concrete TC calls verbatim.

namespace WCPX
{
    Config& Config::Instance()
    {
        static Config inst;
        return inst;
    }

    static std::vector<std::string> SplitWhitespace(std::string const& s)
    {
        std::vector<std::string> out;
        std::istringstream iss(s);
        std::string tok;
        while (iss >> tok)
            if (!tok.empty()) out.push_back(tok);
        return out;
    }

    void Config::Load()
    {
        ServerPrivateKeyPath = sConfigMgr->GetStringDefault(
            "CharacterPortability.Server.PrivateKeyPath", "env/dist/etc/wcpx_server.key");
        ServerName    = sConfigMgr->GetStringDefault("CharacterPortability.Server.Name", "Unnamed");
        ServerContact = sConfigMgr->GetStringDefault("CharacterPortability.Server.Contact", "");
        ServerExpansion = sConfigMgr->GetStringDefault("CharacterPortability.Server.Expansion", "wotlk");

        TrustMode = sConfigMgr->GetStringDefault("CharacterPortability.Trust.Mode", "whitelist");
        TrustWhitelist = SplitWhitespace(
            sConfigMgr->GetStringDefault("CharacterPortability.Trust.Whitelist", ""));
        TofuQueuePath = sConfigMgr->GetStringDefault(
            "CharacterPortability.Trust.TofuQueuePath", "env/dist/etc/wcpx_tofu_pending.txt");

        ExportFreePerMonth = (uint32_t) sConfigMgr->GetIntDefault("CharacterPortability.Export.FreePerMonth", 1);
        ImportRequireToken = sConfigMgr->GetIntDefault("CharacterPortability.Import.RequireTokenId", 1) != 0;
        ExportOutputDir = sConfigMgr->GetStringDefault("CharacterPortability.Export.OutputDir", "wcpx-exports");

        ImportMaxAgeDays = (uint32_t) sConfigMgr->GetIntDefault("CharacterPortability.Import.MaxAgeDays", 0);
        ImportRejectOverLevel = sConfigMgr->GetIntDefault("CharacterPortability.Import.RejectOverLevel", 0) != 0;

        ExportIncludeEquipment = sConfigMgr->GetIntDefault("CharacterPortability.Export.IncludeEquipment", 1) != 0;
        ImportAcceptEquipment  = sConfigMgr->GetIntDefault("CharacterPortability.Import.AcceptEquipment",  1) != 0;

        Argon2TimeCost = (uint32_t) sConfigMgr->GetIntDefault("CharacterPortability.Argon2.TimeCost", 3);
        Argon2MemoryKB = (uint32_t) sConfigMgr->GetIntDefault("CharacterPortability.Argon2.MemoryCostKB", 65536);
        Argon2Parallel = (uint32_t) sConfigMgr->GetIntDefault("CharacterPortability.Argon2.Parallelism", 4);

        HttpEnabled     = sConfigMgr->GetIntDefault("CharacterPortability.Http.Enabled", 0) != 0;
        HttpBindHost    = sConfigMgr->GetStringDefault("CharacterPortability.Http.BindHost", "127.0.0.1");
        HttpBindPort    = static_cast<uint16_t>(sConfigMgr->GetIntDefault("CharacterPortability.Http.BindPort", 7879));
        HttpBearerToken = sConfigMgr->GetStringDefault("CharacterPortability.Http.BearerToken", "");

        TC_LOG_INFO("module", "[WCPX] trust={} whitelist={} freeExport={}/mo requireToken={}",
                 TrustMode, TrustWhitelist.size(), ExportFreePerMonth, ImportRequireToken ? 1 : 0);
    }
}
