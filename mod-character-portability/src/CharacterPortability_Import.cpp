/*
 * WCPX import path.
 *
 * Steps (spec-mandated order):
 *   1. Parse binary container.
 *   2. Verify Ed25519 signature over sig_input (fails-fast, before decrypt).
 *   3. Check `(file_id, source_pubkey)` not already consumed on this server.
 *   4. Check trust mode.
 *   5. Derive key from passphrase + Argon2id parameters from header.
 *   6. AES-256-GCM decrypt payload.
 *   7. Reconcile payload against target-server DB (drop unknowns, clamp level).
 *   8. INSERT new character row + associated tables.
 *   9. Record consumption in wcpx_imported_files.
 */
#include "CharacterPortability.h"

#include "DatabaseEnv.h"
#include "QueryResult.h"
#include "Field.h"
#include "Log.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "World.h"
#include "DBCStores.h"

#include <regex>
#include <sstream>
#include <cctype>

namespace WCPX
{
    namespace {

    // --- Micro JSON reader for header fields we need at import ------------
    // We do NOT decode the full payload with this reader — we round-trip it
    // through Codec::CanonicalizeJson and let a proper JSON library (in
    // upstream integration) walk the structure. For header-only fields, a
    // targeted regex works fine.
    struct HeaderReader
    {
        std::string const& s;
        explicit HeaderReader(std::string const& in) : s(in) {}
        bool GetString(std::string const& dotPath, std::string& out) const
        {
            std::string key = LeafKey(dotPath);
            std::regex re("\"" + key + "\"\\s*:\\s*\"([^\"]*)\"");
            std::smatch m;
            if (std::regex_search(s, m, re)) { out = m[1]; return true; }
            return false;
        }
        bool GetInt(std::string const& dotPath, int64_t& out) const
        {
            std::string key = LeafKey(dotPath);
            std::regex re("\"" + key + "\"\\s*:\\s*(-?\\d+)");
            std::smatch m;
            if (std::regex_search(s, m, re)) { out = std::stoll(m[1]); return true; }
            return false;
        }
        bool GetFloat(std::string const& dotPath, double& out) const
        {
            std::string key = LeafKey(dotPath);
            std::regex re("\"" + key + "\"\\s*:\\s*(-?\\d+\\.?\\d*)");
            std::smatch m;
            if (std::regex_search(s, m, re)) { out = std::stod(m[1]); return true; }
            return false;
        }
        static std::string LeafKey(std::string const& p)
        {
            auto dot = p.find_last_of('.');
            return dot == std::string::npos ? p : p.substr(dot + 1);
        }
    };

    // Compute canonical header-without-signature by stripping the signature
    // key from the canonical form.
    std::string StripSignature(std::string const& canonHeader)
    {
        // Canonical output has signature at "signature": {...} in sorted-key
        // position (comes after "source" alphabetically since 's' == 's', but
        // "signature" > "source", so signature is last-among-s* keys).
        auto pos = canonHeader.find(",\"signature\":");
        if (pos == std::string::npos)
        {
            // Might be the first key if header is otherwise empty.
            pos = canonHeader.find("\"signature\":");
            if (pos == std::string::npos) return canonHeader;
            // Cut through matching brace.
            size_t depth = 0;
            size_t end = pos;
            for (; end < canonHeader.size(); ++end)
            {
                if (canonHeader[end] == '{') depth++;
                else if (canonHeader[end] == '}')
                {
                    depth--;
                    if (depth == 0) { end++; break; }
                }
            }
            std::string result = canonHeader;
            result.erase(pos, end - pos);
            // Clean any resulting ",," or leading ","
            size_t bad = result.find(",,");
            if (bad != std::string::npos) result.erase(bad, 1);
            if (result.size() > 2 && result[1] == ',') result.erase(1, 1);
            return result;
        }
        // Find end of signature value (matching brace).
        size_t depth = 0;
        size_t end = pos + 1; // past the leading comma
        for (; end < canonHeader.size(); ++end)
        {
            if (canonHeader[end] == '{') depth++;
            else if (canonHeader[end] == '}')
            {
                depth--;
                if (depth == 0) { end++; break; }
            }
        }
        std::string result = canonHeader;
        result.erase(pos, end - pos);
        return result;
    }

    bool IsWhitelisted(std::string const& pubB64)
    {
        for (auto const& k : Config::Instance().TrustWhitelist)
            if (k == pubB64) return true;
        return false;
    }

    bool CheckTrust(std::string const& pubB64,
                    std::string const& sourceName,
                    std::string const& sourceCore,
                    std::string const& sourceContact)
    {
        auto& cfg = Config::Instance();
        if (cfg.TrustMode == "open") return true;
        if (IsWhitelisted(pubB64)) return true;
        if (cfg.TrustMode == "tofu")
        {
            // Record for admin review; reject THIS import; return false.
            CharacterDatabase.Execute(
                "INSERT INTO wcpx_pending_pubkeys (source_pubkey, source_name, source_core, source_contact) "
                "VALUES ('{}', '{}', '{}', '{}') "
                "ON DUPLICATE KEY UPDATE seen_count = seen_count + 1",
                pubB64, sourceName, sourceCore, sourceContact);
            LOG_WARN("module", "[WCPX] tofu-pending import from '{}' pubkey {}; admin must approve",
                     sourceName, pubB64);
        }
        return false;
    }

    bool AlreadyConsumed(std::string const& fileId, std::string const& pubB64)
    {
        QueryResult r = CharacterDatabase.Query(
            "SELECT 1 FROM wcpx_imported_files WHERE file_id='{}' AND source_pubkey='{}'",
            fileId, pubB64);
        return r != nullptr;
    }

    // Apply the payload to the target account, returning the new char guid.
    // NOTE: This is deliberately conservative — we CREATE a new character row
    // and populate through supported subtables. Fields we cannot import
    // safely (e.g. mail, inventory, guild membership) are simply not touched.
    uint32_t ApplyPayload(uint32_t accountId, std::string const& payloadJson,
                          std::string& errorOut)
    {
        HeaderReader p(payloadJson);
        std::string name;
        int64_t race = 0, cls = 0, gender = 0, level = 0, xp = 0, played = 0, playedLevel = 0;
        p.GetString("character.name", name);
        p.GetInt("character.race", race);
        p.GetInt("character.class", cls);
        p.GetInt("character.gender", gender);
        p.GetInt("character.level", level);
        p.GetInt("character.xp", xp);
        p.GetInt("character.played_total_seconds", played);
        p.GetInt("character.played_level_seconds", playedLevel);

        // Name normalization + collision handling.
        if (name.empty()) { errorOut = "missing name"; return 0; }
        // Check target-server-side uniqueness.
        for (int suffix = 0; suffix < 100; ++suffix)
        {
            std::string candidate = suffix == 0 ? name : (name + std::to_string(suffix));
            QueryResult ex = CharacterDatabase.Query(
                "SELECT 1 FROM characters WHERE name='{}'", candidate);
            if (!ex) { name = candidate; goto name_ok; }
        }
        errorOut = "name collision"; return 0;
        name_ok:;

        // Level clamp per policy
        auto& cfg = Config::Instance();
        int32_t levelCap = sWorld->getIntConfig(CONFIG_MAX_PLAYER_LEVEL);
        if (level > levelCap)
        {
            if (cfg.ImportRejectOverLevel)
            { errorOut = "exported level exceeds this server's cap"; return 0; }
            level = levelCap;
            xp = 0;
        }

        // Insert character row. We use the ObjectMgr to allocate a new guid.
        uint32_t newGuid = sObjectMgr->GetGenerator<HighGuid::Player>().Generate();

        // Bind location from payload — will be written to character_homebind
        // so the imported character's hearthstone still targets their original
        // home. Default to faction capital if payload lacks bind info.
        bool isHorde = (race == 2 || race == 5 || race == 6 || race == 8 || race == 10);
        int64_t bindMap = 0, bindZone = 1519;
        double bindX = -8842.09, bindY = 626.878, bindZ = 94.043;   // Stormwind Trade District
        if (isHorde) { bindMap = 1; bindZone = 1637; bindX = 1633.75; bindY = -4439.11; bindZ = 15.43; } // Orgrimmar
        p.GetInt("bind.map", bindMap);
        p.GetInt("bind.zone", bindZone);
        p.GetFloat("bind.x", bindX);
        p.GetFloat("bind.y", bindY);
        p.GetFloat("bind.z", bindZ);

        // Spawn (login) location — always faction capital, regardless of bind.
        // Reasoning: player fresh-arrives at a well-known city, then can
        // hearth back to their original bind (which we set below).
        int64_t spawnMap, spawnZone;
        double spawnX, spawnY, spawnZ;
        if (isHorde) {
            spawnMap = 1;  spawnZone = 1637;
            spawnX = 1633.75; spawnY = -4439.11; spawnZ = 15.43;  // Orgrimmar Valley of Strength
        } else {
            spawnMap = 0;  spawnZone = 1519;
            spawnX = -8842.09; spawnY = 626.878; spawnZ = 94.043;  // Stormwind Trade District
        }

        // Cosmetic
        int64_t cSkin=0, cFace=0, cHair=0, cHairColor=0, cFacial=0;
        p.GetInt("cosmetic.skin", cSkin);
        p.GetInt("cosmetic.face", cFace);
        p.GetInt("cosmetic.hair_style", cHair);
        p.GetInt("cosmetic.hair_color", cHairColor);
        p.GetInt("cosmetic.facial_hair", cFacial);

        // The full row insertion is intentionally minimal; a real integration
        // will call Player::Create() with an equivalent PlayerCreateInfo. This
        // block ONLY writes fields that map 1:1 from the WCPX payload plus
        // the minimum set of NOT-NULL-without-default columns AC requires
        // (taximask, innTriggerId) and a spawn location.
        CharacterDatabase.Execute(
            "INSERT INTO characters "
            "(guid, account, name, race, class, gender, level, xp, "
            " skin, face, hairStyle, hairColor, facialStyle, "
            " position_x, position_y, position_z, orientation, map, zone, "
            " totaltime, leveltime, at_login, "
            " taximask, innTriggerId, health, power1, activeTalentGroup, talentGroupsCount) "
            "VALUES ({}, {}, '{}', {}, {}, {}, {}, {}, "
            " {}, {}, {}, {}, {}, "
            " {}, {}, {}, 0, {}, {}, "
            " {}, {}, 0, "
            " '0 0 0 0 0 0 0 0', 0, {}, 100, 0, 2)",
            newGuid, accountId, name, race, cls, gender, level, xp,
            cSkin, cFace, cHair, cHairColor, cFacial,
            spawnX, spawnY, spawnZ, spawnMap, spawnZone,
            played, playedLevel,
            level * 100);

        // Write homebind so hearthstone works after import.
        CharacterDatabase.Execute(
            "REPLACE INTO character_homebind (guid, mapId, zoneId, posX, posY, posZ) "
            "VALUES ({}, {}, {}, {}, {}, {})",
            newGuid, bindMap, bindZone, bindX, bindY, bindZ);

        // Spells
        std::regex spellRe("\"spells\"\\s*:\\s*\\[([^\\]]*)\\]");
        std::smatch sm;
        int spellsInserted = 0, spellsSkipped = 0;
        if (std::regex_search(payloadJson, sm, spellRe))
        {
            std::string body = sm[1];
            std::istringstream iss(body);
            uint32_t sid;
            char comma;
            while (iss >> sid)
            {
                if (sSpellStore.LookupEntry(sid))
                {
                    CharacterDatabase.Execute(
                        "INSERT IGNORE INTO character_spell (guid, spell, specMask) "
                        "VALUES ({}, {}, 1)", newGuid, sid);
                    spellsInserted++;
                } else {
                    spellsSkipped++;
                }
                iss >> comma;
            }
        }
        LOG_INFO("module", "[WCPX] import: spells inserted={} skipped={}",
                 spellsInserted, spellsSkipped);

        // Achievements — regex the array of objects; per-object regex.
        std::regex achRe("\"achievements\"\\s*:\\s*\\[([^\\]]*)\\]");
        int achievementsInserted = 0;
        if (std::regex_search(payloadJson, sm, achRe))
        {
            std::string body = sm[1];
            std::regex objRe("\\{\"date\":\"([^\"]+)\",\"id\":(\\d+)\\}");
            auto begin = std::sregex_iterator(body.begin(), body.end(), objRe);
            auto end   = std::sregex_iterator();
            for (auto it = begin; it != end; ++it)
            {
                uint32_t achId = std::stoul((*it)[2].str());
                CharacterDatabase.Execute(
                    "INSERT IGNORE INTO character_achievement (guid, achievement, date) "
                    "VALUES ({}, {}, UNIX_TIMESTAMP())", newGuid, achId);
                achievementsInserted++;
            }
        }
        LOG_INFO("module", "[WCPX] import: achievements inserted={}", achievementsInserted);

        // Reputation
        std::regex repRe("\"reputation\"\\s*:\\s*\\[([^\\]]*)\\]");
        if (std::regex_search(payloadJson, sm, repRe))
        {
            std::string body = sm[1];
            std::regex objRe("\\{\"faction_id\":(\\d+),\"flags\":(\\d+),\"standing\":(-?\\d+)\\}");
            auto begin = std::sregex_iterator(body.begin(), body.end(), objRe);
            auto end   = std::sregex_iterator();
            for (auto it = begin; it != end; ++it)
            {
                uint32_t fid  = std::stoul((*it)[1].str());
                uint32_t flag = std::stoul((*it)[2].str());
                int32_t stand = std::stol((*it)[3].str());
                CharacterDatabase.Execute(
                    "INSERT IGNORE INTO character_reputation (guid, faction, standing, flags) "
                    "VALUES ({}, {}, {}, {})", newGuid, fid, stand, flag);
            }
        }

        // Skills
        std::regex skRe("\"skills\"\\s*:\\s*\\[([^\\]]*)\\]");
        if (std::regex_search(payloadJson, sm, skRe))
        {
            std::string body = sm[1];
            std::regex objRe("\\{\"max\":(\\d+),\"skill_id\":(\\d+),\"value\":(\\d+)\\}");
            auto begin = std::sregex_iterator(body.begin(), body.end(), objRe);
            auto end   = std::sregex_iterator();
            for (auto it = begin; it != end; ++it)
            {
                uint32_t maxV = std::stoul((*it)[1].str());
                uint32_t sid  = std::stoul((*it)[2].str());
                uint32_t val  = std::stoul((*it)[3].str());
                CharacterDatabase.Execute(
                    "INSERT IGNORE INTO character_skills (guid, skill, value, max) "
                    "VALUES ({}, {}, {}, {})", newGuid, sid, val, maxV);
            }
        }

        // Talents
        std::regex tlRe("\"talents\"\\s*:\\s*\\[([^\\]]*)\\]");
        int talentsInserted = 0;
        if (std::regex_search(payloadJson, sm, tlRe))
        {
            std::string body = sm[1];
            std::regex objRe("\\{\"current_rank\":(\\d+),\"spec\":(\\d+),\"spell_id\":(\\d+)\\}");
            auto begin = std::sregex_iterator(body.begin(), body.end(), objRe);
            auto end   = std::sregex_iterator();
            for (auto it = begin; it != end; ++it)
            {
                uint32_t spell = std::stoul((*it)[3].str());
                uint32_t spec  = std::stoul((*it)[2].str());
                uint8_t specMask = (spec == 0) ? 0x01 : 0x02;
                CharacterDatabase.Execute(
                    "INSERT IGNORE INTO character_talent (guid, spell, specMask) "
                    "VALUES ({}, {}, {})", newGuid, spell, (unsigned)specMask);
                talentsInserted++;
            }
        }
        LOG_INFO("module", "[WCPX] import: talents inserted={}", talentsInserted);

        return newGuid;
    }

    } // anonymous

    ImportResult DoImport(ImportRequest const& req)
    {
        ImportResult res;

        // 1. Load file into WcpxFile
        WcpxFile file;
        std::string err;
        if (!req.filePath.empty())
        {
            if (!Codec::ReadFile(req.filePath, file, err))
            { res.errorMessage = "read failed: " + err; return res; }
        }
        else if (!req.bytes.empty())
        {
            if (!Codec::ReadBytes(req.bytes, file, err))
            { res.errorMessage = "read failed: " + err; return res; }
        }
        else
        { res.errorMessage = "no input"; return res; }

        // Extract header fields we need
        HeaderReader hr(file.headerJson);
        std::string fileId, pubB64, sourceName, sourceCore, sourceContact;
        std::string sigB64, saltB64, ivB64;
        int64_t tCost = 3, mCost = 65536, par = 4;
        std::string wcpxVer;

        hr.GetString("wcpx", wcpxVer);
        if (wcpxVer != "1.0")
        { res.errorMessage = "unsupported WCPX version: " + wcpxVer; return res; }

        hr.GetString("file_id", fileId);
        hr.GetString("source.pubkey", pubB64);
        hr.GetString("source.name", sourceName);
        hr.GetString("source.core", sourceCore);
        hr.GetString("source.contact", sourceContact);
        hr.GetString("signature.value", sigB64);
        hr.GetString("encryption.kdf_salt", saltB64);
        hr.GetString("encryption.iv", ivB64);
        hr.GetInt("encryption.kdf_time_cost", tCost);
        hr.GetInt("encryption.kdf_memory_cost", mCost);
        hr.GetInt("encryption.kdf_parallelism", par);

        if (fileId.empty() || pubB64.empty() || sigB64.empty())
        { res.errorMessage = "malformed header"; return res; }

        // 2. Verify signature
        std::vector<uint8_t> pubRaw, sigRaw;
        if (!Crypto::Base64Decode(pubB64, pubRaw) || pubRaw.size() != 32)
        { res.errorMessage = "bad pubkey encoding"; return res; }
        if (!Crypto::Base64Decode(sigB64, sigRaw))
        { res.errorMessage = "bad signature encoding"; return res; }

        std::string canonHeader = Codec::CanonicalizeJson(file.headerJson);
        std::string canonNoSig = StripSignature(canonHeader);

        std::vector<uint8_t> sigInput;
        static const char prefix[] = "wcpx-v1\n";
        sigInput.insert(sigInput.end(), prefix, prefix + sizeof(prefix) - 1);
        sigInput.insert(sigInput.end(), canonNoSig.begin(), canonNoSig.end());
        sigInput.push_back('\n');
        sigInput.insert(sigInput.end(), file.payloadCiphertext.begin(), file.payloadCiphertext.end());
        sigInput.insert(sigInput.end(), file.payloadTag.begin(), file.payloadTag.end());

        if (!Crypto::Verify(pubRaw, sigInput, sigRaw))
        { res.errorMessage = "signature invalid"; return res; }

        // 3. Replay protection
        if (AlreadyConsumed(fileId, pubB64))
        { res.errorMessage = "file already imported on this server"; return res; }

        // 4. Trust
        if (!CheckTrust(pubB64, sourceName, sourceCore, sourceContact))
        { res.errorMessage = "source server not trusted"; return res; }

        // 5. Decrypt
        std::vector<uint8_t> salt, iv;
        if (!Crypto::Base64Decode(saltB64, salt) || salt.empty())
        { res.errorMessage = "bad salt"; return res; }
        if (!Crypto::Base64Decode(ivB64, iv) || iv.size() != 12)
        { res.errorMessage = "bad iv"; return res; }
        auto key = Crypto::DeriveKey(req.passphrase, salt,
                                     static_cast<uint32_t>(tCost),
                                     static_cast<uint32_t>(mCost),
                                     static_cast<uint32_t>(par));
        if (key.empty()) { res.errorMessage = "kdf failed"; return res; }

        std::vector<uint8_t> pt;
        if (!Crypto::AeadDecrypt(key, iv, {}, file.payloadCiphertext, file.payloadTag, pt))
        { res.errorMessage = "wrong passphrase or tampered payload"; return res; }
        std::string payload(pt.begin(), pt.end());
        std::string canonPayload = Codec::CanonicalizeJson(payload);
        if (canonPayload.empty())
        { res.errorMessage = "payload not valid JSON"; return res; }

        // 6. Apply
        uint32_t newGuid = ApplyPayload(req.targetAccountId, canonPayload, err);
        if (!newGuid) { res.errorMessage = err; return res; }

        // 7. Record consumption
        CharacterDatabase.Execute(
            "INSERT INTO wcpx_imported_files (file_id, source_pubkey, account_id, character_id, source_name) "
            "VALUES ('{}', '{}', {}, {}, '{}')",
            fileId, pubB64, req.targetAccountId, newGuid, sourceName);

        res.ok = true;
        res.newCharacterGuid = newGuid;
        LOG_INFO("module", "[WCPX] imported char '{}' as guid={} from source '{}'",
                 fileId, newGuid, sourceName);
        return res;
    }
}
