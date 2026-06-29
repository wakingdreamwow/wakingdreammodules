/*
 * mod-event-loot : World Boss Event System
 *  - Data-driven roster (event_worldbosses): which creatures are event bosses, elite vs rare, loot quality
 *  - Multi-boss tracking
 *  - Announcements (spawn / periodic / death)
 *  - Elite bosses: immersive helper-bot waves (offset + trickle) auto-grouped with the engaging player (heal+assist)
 *  - Level-tailored personal loot by mail (picks existing items matching each looter's level/class/quality)
 */
#include "ScriptMgr.h"
#include "Player.h"
#include "Creature.h"
#include "Config.h"
#include "Chat.h"
#include "Mail.h"
#include "Item.h"
#include "Random.h"
#include "ThreatManager.h"
#include "ObjectAccessor.h"
#include "MapMgr.h"
#include "Group.h"
#include "GroupMgr.h"
#include "DatabaseEnv.h"
#include "Playerbots.h"
#include "RandomPlayerbotMgr.h"
#include "PlayerbotAI.h"
#include "Log.h"
#include <map>
#include <set>
#include <string>
#include <cmath>

namespace
{
    struct BossDef { bool elite; uint32 lootQ; };
    std::map<uint32, BossDef> s_roster; bool s_rosterLoaded=false;
    void LoadRoster()
    {
        if (s_rosterLoaded) return; s_rosterLoaded=true;
        if (QueryResult r = WorldDatabase.Query("SELECT entry, is_elite, loot_quality FROM event_worldbosses"))
            do { Field* f=r->Fetch(); s_roster[f[0].Get<uint32>()] = { f[1].Get<uint8>()!=0, (uint32)f[2].Get<uint8>() }; } while (r->NextRow());
    }
    bool GetBossDef(uint32 entry, BossDef& out){ LoadRoster(); auto it=s_roster.find(entry); if(it==s_roster.end())return false; out=it->second; return true; }

    struct BossState { uint32 map; std::string name; bool elite; uint32 lootQ; uint32 annAcc; uint32 seekAcc; std::set<ObjectGuid> bots; };
    std::map<ObjectGuid, BossState> s_bosses;

    bool cfgBool(char const* k,bool d){ return sConfigMgr->GetOption<bool>(k,d); }
    uint32 cfgU(char const* k,uint32 d){ return sConfigMgr->GetOption<uint32>(k,d); }

    void Broadcast(std::string const& msg){
        for (auto const& it : ObjectAccessor::GetPlayers())
            if (Player* p=it.second) if (p->IsInWorld()&&p->GetSession())
                ChatHandler(p->GetSession()).SendSysMessage(msg);
    }
    Player* FindLeader(Creature* boss){
        Player* best=nullptr; float bd=1e9f;
        for (auto const& it : ObjectAccessor::GetPlayers()){ Player* p=it.second;
            if(!p||!p->IsInWorld()||!p->IsAlive()||GET_PLAYERBOT_AI(p))continue;
            if(p->GetMapId()!=boss->GetMapId())continue;
            float d=p->GetDistance(boss); if(d<100.f&&d<bd){bd=d;best=p;} }
        return best;
    }
    void ReleaseBots(std::set<ObjectGuid>& bots){
        for (ObjectGuid g : bots){ Player* b=ObjectAccessor::FindPlayer(g); if(!b)continue;
            if(Group* gg=b->GetGroup()) gg->RemoveMember(g);
            if(PlayerbotAI* ai=GET_PLAYERBOT_AI(b)){ ai->SetMaster(nullptr); ai->ResetStrategies(); } }
        bots.clear();
    }
    void SeekBots(Creature* boss, BossState& st){
        if(!cfgBool("EventLoot.AutoRaid.Enable",true)) return;
        Player* leader=FindLeader(boss); if(!leader) return;
        Group* grp=leader->GetGroup();
        if(grp&&grp->GetLeaderGUID()!=leader->GetGUID())return;
        if(!grp){ grp=new Group(); if(!grp->Create(leader)){delete grp;return;} sGroupMgr->AddGroup(grp);}
        if(!grp->isRaidGroup()) grp->ConvertToRaid();
        TeamId team=leader->GetTeamId();
        int bl=(int)boss->GetLevel();
        int range=(int)cfgU("EventLoot.BotSeek.LevelRange",5);
        uint32 maxBots=cfgU("EventLoot.AutoRaid.MaxBots",20);
        int maxWave=(int)cfgU("EventLoot.BotSeek.MaxPerWave",3);
        int needT=(int)cfgU("EventLoot.AutoRaid.Tanks",2);
        int needH=(int)cfgU("EventLoot.AutoRaid.Heals",5);
        int curT=0,curH=0;
        for (GroupReference* ref=grp->GetFirstMember(); ref; ref=ref->next()){
            Player* m=ref->GetSource(); if(!m) continue;
            if(PlayerbotAI::IsTank(m,true)) curT++; else if(PlayerbotAI::IsHeal(m,true)) curH++;
        }
        int wantT=needT>curT?needT-curT:0; int wantH=needH>curH?needH-curH:0;
        int wave=0;
        for(int pass=0; pass<3; ++pass){
            for (auto const& it : sRandomPlayerbotMgr.GetAllBots()){
                if(st.bots.size()>=maxBots||grp->IsFull()||wave>=maxWave) break;
                Player* bot=it.second;
                if(!bot||!bot->IsInWorld()||!bot->IsAlive()||bot->IsInCombat()||bot->GetGroup())continue;
                if(bot->GetTeamId()!=team)continue;
                int lvl=(int)bot->GetLevel(); if(lvl<bl-range||lvl>bl+range)continue;
                bool isT=PlayerbotAI::IsTank(bot,true); bool isH=(!isT)&&PlayerbotAI::IsHeal(bot,true);
                if(pass==0){ if(!isT||wantT<=0) continue; }
                else if(pass==1){ if(!isH||wantH<=0) continue; }
                else { if(isT||isH) continue; }
                float ang=frand(0.f,6.2831f), dist=frand(10.f,22.f);
                bot->TeleportTo(boss->GetMapId(), boss->GetPositionX()+std::cos(ang)*dist, boss->GetPositionY()+std::sin(ang)*dist, boss->GetPositionZ()+1.f, ang+3.1416f);
                if(grp->AddMember(bot)){ if(PlayerbotAI* ai=GET_PLAYERBOT_AI(bot)){ai->SetMaster(leader);ai->ResetStrategies();} st.bots.insert(bot->GetGUID()); if(pass==0)wantT--; else if(pass==1)wantH--; ++wave; }
            }
        }
    }
    std::string ClassGearFilter(Player* p, uint32 blvl){
        uint8 c=p->getClass();
        std::string armor="0"; // misc (neck/ring/trinket/cloak/held) for all
        if(c==5||c==8||c==9) armor+=",1";                 // cloth: priest/mage/warlock
        else if(c==4||c==11) armor+=",2";                 // leather: rogue/druid
        else if(c==3||c==7){ armor += (blvl>=40?",3":",2"); if(c==7) armor+=",6"; } // mail@40 else leather; shaman shield
        else if(c==1||c==2) armor += (blvl>=40?",4,6":",3,6"); // plate@40 else mail; +shield
        else if(c==6) armor+=",4";                        // DK plate
        std::string wpn;
        switch(c){
            case 1: wpn="0,1,4,5,6,7,8,10,13,15"; break;  // warrior
            case 2: wpn="0,1,4,5,6,7,8"; break;           // paladin
            case 3: wpn="0,1,2,3,6,7,8,10,13,15,18"; break; // hunter
            case 4: wpn="0,2,3,4,7,13,15,16,18"; break;   // rogue
            case 5: wpn="4,10,15,19"; break;              // priest
            case 6: wpn="0,1,4,5,6,7,8"; break;           // DK
            case 7: wpn="0,4,5,10,13,15"; break;          // shaman
            case 8: wpn="7,10,15,19"; break;              // mage
            case 9: wpn="7,10,15,19"; break;              // warlock
            case 11: wpn="4,5,6,10,13,15"; break;         // druid
            default: wpn="7,15"; break;
        }
        return "((class=4 AND subclass IN ("+armor+")) OR (class=2 AND subclass IN ("+wpn+")))";
    }
    void GiveLootBag(Player* p, uint32 quality, uint32 blvl){
        uint32 cmask=1u<<(p->getClass()-1);
        uint32 gearLo = blvl>5?(blvl-5):1u;
        uint32 matLo = blvl>30?(blvl-30):1u;
        uint32 gold = blvl * cfgU("EventLoot.MoneyPerLevel",5000);
        CharacterDatabaseTransaction trans=CharacterDatabase.BeginTransaction();
        MailDraft draft("World Boss Loot","Your tailored share: gear, materials, and gold.");
        bool any=false;
        if(gold>0){ draft.AddMoney(gold); any=true; }
        std::string gq="SELECT entry FROM item_template WHERE Quality="+std::to_string(quality)+" AND RequiredLevel BETWEEN "+std::to_string(gearLo)+" AND "+std::to_string(blvl)+" AND InventoryType>0 AND name NOT LIKE '%test%' AND name NOT LIKE '%Deprecated%' AND name NOT LIKE '%Monster -%' AND (AllowableClass=-1 OR (AllowableClass & "+std::to_string(cmask)+")<>0) AND "+ClassGearFilter(p,blvl)+" ORDER BY RAND() LIMIT 2";
        if(QueryResult r=WorldDatabase.Query(gq))
            do{ uint32 id=r->Fetch()[0].Get<uint32>(); if(Item* i=Item::CreateItem(id,1,p)){i->SaveToDB(trans);draft.AddItem(i);any=true;} }while(r->NextRow());
        if(QueryResult r=WorldDatabase.Query("SELECT entry, stackable FROM item_template WHERE class=7 AND Quality<=3 AND ItemLevel BETWEEN {} AND {} ORDER BY RAND() LIMIT 3", matLo, blvl))
            do{ Field* f=r->Fetch(); uint32 id=f[0].Get<uint32>(); int32 st=f[1].Get<int32>(); uint32 cnt=urand(20,40); if(st>0 && (int32)cnt>st) cnt=(uint32)st; if(Item* i=Item::CreateItem(id,cnt?cnt:1u,p)){i->SaveToDB(trans);draft.AddItem(i);any=true;} }while(r->NextRow());
        if(any) draft.SendMailTo(trans, MailReceiver(p), MailSender(MAIL_NORMAL, p->GetGUID().GetCounter(), MAIL_STATIONERY_GM));
        CharacterDatabase.CommitTransaction(trans);
    }
}

class EventLootUnit : public UnitScript
{
public:
    EventLootUnit() : UnitScript("EventLootUnit", true, { UNITHOOK_ON_UNIT_DEATH }) {}
    void OnUnitDeath(Unit* unit, Unit* /*killer*/) override {
        if(!cfgBool("EventLoot.Enable",true)) return;
        Creature* boss=unit?unit->ToCreature():nullptr; if(!boss) return;
        BossDef d; if(!GetBossDef(boss->GetEntry(), d)) return;
        auto it=s_bosses.find(boss->GetGUID());
        uint32 lootQ = (it!=s_bosses.end()) ? it->second.lootQ : (d.lootQ?d.lootQ:(d.elite?4u:3u));
        if(it!=s_bosses.end()){ ReleaseBots(it->second.bots); s_bosses.erase(it); }
        if(cfgBool("EventLoot.Announce.Enable",true))
            Broadcast("|cff20ff20[World Boss]|r "+boss->GetName()+" has been defeated! Loot is on the way.");
        std::set<uint32> done; int n=0;
        for (auto const& pit : ObjectAccessor::GetPlayers()){
            Player* p=pit.second;
            if(!p||!p->IsInWorld()||!p->IsAlive()||GET_PLAYERBOT_AI(p))continue;
            if(p->GetMapId()!=boss->GetMapId()||!p->IsWithinDist(boss,150.0f))continue;
            if(!done.insert(p->GetGUID().GetCounter()).second)continue;
            GiveLootBag(p, lootQ, boss->GetLevel());
            ChatHandler(p->GetSession()).PSendSysMessage("|cff33ff99[Event Loot]|r Your share is waiting in your mailbox!");
            ++n;
        }
        LOG_INFO("module.eventloot","[EventLoot] {} bezwungen, {} Spieler beschenkt (Q{})", boss->GetName(), n, lootQ);
    }
};
class EventLootSpawn : public AllCreatureScript
{
public:
    EventLootSpawn() : AllCreatureScript("EventLootSpawn") {}
    void OnCreatureAddWorld(Creature* c) override {
        if(!c) return; BossDef d; if(!GetBossDef(c->GetEntry(),d)) return;
        BossState st; st.map=c->GetMapId(); st.name=c->GetName(); st.elite=d.elite;
        st.lootQ = d.lootQ ? d.lootQ : (d.elite?4u:3u); st.annAcc=0; st.seekAcc=0;
        s_bosses[c->GetGUID()]=st;
        if(cfgBool("EventLoot.Announce.Enable",true))
            Broadcast("|cffff2020[World Boss]|r "+st.name+" has appeared! Stand against it!");
        if(st.elite) SeekBots(c, s_bosses[c->GetGUID()]);
    }
};
class EventLootWorld : public WorldScript
{
public:
    EventLootWorld() : WorldScript("EventLootWorld", { WORLDHOOK_ON_UPDATE }) {}
    void OnUpdate(uint32 diff) override {
        if(s_bosses.empty()) return;
        for(auto it=s_bosses.begin(); it!=s_bosses.end();){
            Map* m=sMapMgr->FindMap(it->second.map,0);
            Creature* boss=m?m->GetCreature(it->first):nullptr;
            if(!boss||!boss->IsAlive()){ ReleaseBots(it->second.bots); it=s_bosses.erase(it); continue; }
            if(cfgBool("EventLoot.Announce.Enable",true)){
                it->second.annAcc+=diff; uint32 iv=cfgU("EventLoot.Announce.IntervalMinutes",30)*60000u;
                if(iv&&it->second.annAcc>=iv){ it->second.annAcc=0; Broadcast("|cffff2020[World Boss]|r "+it->second.name+" still lives and awaits challengers!"); } }
            if(it->second.elite&&cfgBool("EventLoot.BotSeek.Enable",true)){
                it->second.seekAcc+=diff; uint32 wv=cfgU("EventLoot.BotSeek.WaveSeconds",20)*1000u;
                if(wv&&it->second.seekAcc>=wv){ it->second.seekAcc=0; SeekBots(boss, it->second); } }
            ++it;
        }
    }
};
void AddEventLootScripts(){ new EventLootUnit(); new EventLootSpawn(); new EventLootWorld(); }
