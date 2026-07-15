#include "CharacterPortability.h"
#include "Config.h"
#include "Log.h"
#include <sstream>

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
        ServerPrivateKeyPath = sConfigMgr->GetOption<std::string>(
            "CharacterPortability.Server.PrivateKeyPath", "env/dist/etc/wcpx_server.key");
        ServerName    = sConfigMgr->GetOption<std::string>("CharacterPortability.Server.Name", "Unnamed");
        ServerContact = sConfigMgr->GetOption<std::string>("CharacterPortability.Server.Contact", "");
        ServerExpansion = sConfigMgr->GetOption<std::string>("CharacterPortability.Server.Expansion", "wotlk");

        TrustMode = sConfigMgr->GetOption<std::string>("CharacterPortability.Trust.Mode", "whitelist");
        TrustWhitelist = SplitWhitespace(
            sConfigMgr->GetOption<std::string>("CharacterPortability.Trust.Whitelist", ""));
        TofuQueuePath = sConfigMgr->GetOption<std::string>(
            "CharacterPortability.Trust.TofuQueuePath", "env/dist/etc/wcpx_tofu_pending.txt");

        ExportFreePerMonth = sConfigMgr->GetOption<uint32_t>("CharacterPortability.Export.FreePerMonth", 1);
        ImportRequireToken = sConfigMgr->GetOption<int32_t>("CharacterPortability.Import.RequireTokenId", 1) != 0;
        ExportOutputDir = sConfigMgr->GetOption<std::string>("CharacterPortability.Export.OutputDir", "wcpx-exports");

        ImportMaxAgeDays = sConfigMgr->GetOption<uint32_t>("CharacterPortability.Import.MaxAgeDays", 0);
        ImportRejectOverLevel = sConfigMgr->GetOption<int32_t>("CharacterPortability.Import.RejectOverLevel", 0) != 0;

        ExportIncludeEquipment = sConfigMgr->GetOption<int32_t>("CharacterPortability.Export.IncludeEquipment", 1) != 0;
        ImportAcceptEquipment  = sConfigMgr->GetOption<int32_t>("CharacterPortability.Import.AcceptEquipment",  1) != 0;

        Argon2TimeCost = sConfigMgr->GetOption<uint32_t>("CharacterPortability.Argon2.TimeCost", 3);
        Argon2MemoryKB = sConfigMgr->GetOption<uint32_t>("CharacterPortability.Argon2.MemoryCostKB", 65536);
        Argon2Parallel = sConfigMgr->GetOption<uint32_t>("CharacterPortability.Argon2.Parallelism", 4);

        HttpEnabled     = sConfigMgr->GetOption<int32_t>("CharacterPortability.Http.Enabled", 0) != 0;
        HttpBindHost    = sConfigMgr->GetOption<std::string>("CharacterPortability.Http.BindHost", "127.0.0.1");
        HttpBindPort    = static_cast<uint16_t>(sConfigMgr->GetOption<uint32_t>("CharacterPortability.Http.BindPort", 7879));
        HttpBearerToken = sConfigMgr->GetOption<std::string>("CharacterPortability.Http.BearerToken", "");

        LOG_INFO("module", "[WCPX] trust={} whitelist={} freeExport={}/mo requireToken={}",
                 TrustMode, TrustWhitelist.size(), ExportFreePerMonth, ImportRequireToken ? 1 : 0);
    }
}
