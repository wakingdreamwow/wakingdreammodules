#include "CharacterPortability.h"
#include "Log.h"

void AddSC_mod_character_portabilityScripts()
{
    WCPX::Config::Instance().Load();
    WCPX::RegisterChatCommands();
    WCPX::StartHttpServer();
    TC_LOG_INFO("module", "mod-character-portability loaded (WCPX-1.0, server: {})",
             WCPX::Config::Instance().ServerName);
}
