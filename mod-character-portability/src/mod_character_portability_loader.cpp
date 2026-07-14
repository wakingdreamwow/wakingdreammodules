#include "CharacterPortability.h"
#include "Log.h"

void Addmod_character_portabilityScripts()
{
    WCPX::Config::Instance().Load();
    WCPX::RegisterChatCommands();
    LOG_INFO("module", "mod-character-portability loaded (WCPX-1.0, server: {})",
             WCPX::Config::Instance().ServerName);
}
