/*
 * WCPX export path.
 *
 * Reads a character's row-set from the `characters` DB and produces a signed,
 * encrypted .wcpx file per SPEC §5-§6.
 *
 * SQL is deliberately explicit (no ORM) to make the mapping to the WCPX
 * payload schema trivial to audit.
 */
#include "CharacterPortability.h"

#include "DatabaseEnv.h"
#include "QueryResult.h"
#include "Field.h"
#include "Log.h"

#include <openssl/evp.h>
#include <openssl/pem.h>

#include <chrono>
#include <ctime>
#include <sstream>
#include <iomanip>
#include <random>
#include <cstring>

namespace WCPX
{
    // --- Utilities ---------------------------------------------------------

    static std::string IsoUtcNow()
    {
        auto now = std::chrono::system_clock::now();
        std::time_t t = std::chrono::system_clock::to_time_t(now);
        std::tm tm{};
#if defined(_WIN32)
        gmtime_s(&tm, &t);
#else
        gmtime_r(&t, &tm);
#endif
        std::ostringstream oss;
        oss << std::put_time(&tm, "%Y-%m-%dT%H:%M:%SZ");
        return oss.str();
    }

    static std::string UuidV4()
    {
        auto b = Crypto::RandomBytes(16);
        // Per RFC 4122 §4.4: set version 4 and variant bits.
        b[6] = (b[6] & 0x0F) | 0x40;
        b[8] = (b[8] & 0x3F) | 0x80;
        static const char hex[] = "0123456789abcdef";
        std::string s(36, '-');
        int pos = 0;
        for (int i = 0; i < 16; ++i)
        {
            if (i == 4 || i == 6 || i == 8 || i == 10) ++pos; // hyphen
            s[pos++] = hex[b[i] >> 4];
            s[pos++] = hex[b[i] & 0x0F];
        }
        return s;
    }

    static std::string JsonEscape(std::string const& s)
    {
        std::ostringstream out;
        for (unsigned char c : s)
        {
            switch (c)
            {
                case '"':  out << "\\\""; break;
                case '\\': out << "\\\\"; break;
                case '\n': out << "\\n"; break;
                case '\r': out << "\\r"; break;
                case '\t': out << "\\t"; break;
                default:
                    if (c < 0x20)
                    {
                        out << "\\u" << std::hex << std::setw(4) << std::setfill('0')
                            << static_cast<int>(c) << std::dec;
                    }
                    else out << c;
            }
        }
        return out.str();
    }

    // --- Rate limit check --------------------------------------------------
    static bool CheckExportQuota(uint32_t accountId, bool bypass)
    {
        if (bypass) return true;
        auto& cfg = Config::Instance();
        if (cfg.ExportFreePerMonth == 0) return false; // paid-only server
        QueryResult r = CharacterDatabase.PQuery(
            "SELECT COUNT(*) FROM wcpx_export_log "
            "WHERE account_id={} AND was_paid=0 "
            "AND exported_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)",
            accountId);
        if (!r) return false;
        uint64_t used = r->Fetch()[0].GetUInt64();
        return used < cfg.ExportFreePerMonth;
    }

    // --- Payload build -----------------------------------------------------
    // Emits UTF-8 JSON in write-order; we canonicalize later so key order here
    // doesn't matter.
    static std::string BuildPayload(uint32_t guid, std::string& errorOut)
    {
        QueryResult r = CharacterDatabase.PQuery(
            "SELECT name, race, class, gender, level, xp, totaltime, leveltime, "
            "       skin, face, hairStyle, hairColor, facialStyle, "
            "       activeTalentGroup "
            "FROM characters WHERE guid={}", guid);
        if (!r) { errorOut = "character not found"; return {}; }
        auto row = r->Fetch();

        std::string name = row[0].GetString();
        uint8_t  race = row[1].GetUInt8();
        uint8_t  cls  = row[2].GetUInt8();
        uint8_t  gender = row[3].GetUInt8();
        uint32_t level = row[4].GetUInt32();
        uint32_t xp    = row[5].GetUInt32();
        uint32_t totalTime = row[6].GetUInt32();
        uint32_t levelTime = row[7].GetUInt32();
        uint8_t  skin = row[8].GetUInt8();
        uint8_t  face = row[9].GetUInt8();
        uint8_t  hairStyle = row[10].GetUInt8();
        uint8_t  hairColor = row[11].GetUInt8();
        uint8_t  facialStyle = row[12].GetUInt8();
        uint8_t activeSpec = row[13].GetUInt8();

        // Homebind (separate table in AC / TC-335 / cMaNGOS)
        uint32_t bindMap = 0, bindZone = 0;
        float bx = 0.f, by = 0.f, bz = 0.f;
        if (QueryResult hb = CharacterDatabase.PQuery(
                "SELECT mapId, zoneId, posX, posY, posZ FROM character_homebind WHERE guid={}", guid))
        {
            auto hbrow = hb->Fetch();
            bindMap  = hbrow[0].GetUInt16();
            bindZone = hbrow[1].GetUInt16();
            bx = hbrow[2].GetFloat();
            by = hbrow[3].GetFloat();
            bz = hbrow[4].GetFloat();
        }

        std::string faction = (race == 1 || race == 3 || race == 4 || race == 7 || race == 11)
                              ? "alliance" : "horde";

        std::ostringstream j;
        j << "{";
        j << "\"wcpx_payload\":\"1.0\",";
        j << "\"active_spec\":" << (int)activeSpec << ",";
        j << "\"character\":{"
          << "\"name\":\"" << JsonEscape(name) << "\","
          << "\"race\":" << (int)race << ","
          << "\"class\":" << (int)cls << ","
          << "\"gender\":" << (int)gender << ","
          << "\"level\":" << level << ","
          << "\"xp\":" << xp << ","
          << "\"played_total_seconds\":" << totalTime << ","
          << "\"played_level_seconds\":" << levelTime << ","
          << "\"faction\":\"" << faction << "\","
          << "\"cosmetic\":{"
            << "\"skin\":" << (int)skin << ","
            << "\"face\":" << (int)face << ","
            << "\"hair_style\":" << (int)hairStyle << ","
            << "\"hair_color\":" << (int)hairColor << ","
            << "\"facial_hair\":" << (int)facialStyle
          << "},"
          << "\"bind\":{"
            << "\"map\":" << bindMap << ","
            << "\"zone\":" << bindZone << ","
            << "\"x\":" << bx << ",\"y\":" << by << ",\"z\":" << bz << ",\"o\":0"
          << "}"
          << "},";

        // Talents
        j << "\"talents\":[";
        {
            QueryResult t = CharacterDatabase.PQuery(
                "SELECT spell, specMask FROM character_talent WHERE guid={}", guid);
            bool first = true;
            if (t) do
            {
                auto tr = t->Fetch();
                if (!first) j << ",";
                first = false;
                uint32_t spell = tr[0].GetUInt32();
                uint8_t specMask = tr[1].GetUInt8();
                uint8_t spec = (specMask & 0x02) ? 1 : 0;
                j << "{\"spell_id\":" << spell << ",\"current_rank\":1,\"spec\":" << (int)spec << "}";
            } while (t->NextRow());
        }
        j << "],";

        // Spells
        j << "\"spells\":[";
        {
            QueryResult s = CharacterDatabase.PQuery(
                "SELECT spell FROM character_spell WHERE guid={}", guid);
            bool first = true;
            if (s) do
            {
                auto sr = s->Fetch();
                if (!first) j << ",";
                first = false;
                j << sr[0].GetUInt32();
            } while (s->NextRow());
        }
        j << "],";

        // Achievements
        j << "\"achievements\":[";
        {
            QueryResult a = CharacterDatabase.PQuery(
                "SELECT achievement, date FROM character_achievement WHERE guid={}", guid);
            bool first = true;
            if (a) do
            {
                auto ar = a->Fetch();
                if (!first) j << ",";
                first = false;
                uint32_t id = ar[0].GetUInt32();
                uint32_t ts = ar[1].GetUInt32();
                std::time_t tt = static_cast<std::time_t>(ts);
                std::tm gm{};
#if defined(_WIN32)
                gmtime_s(&gm, &tt);
#else
                gmtime_r(&tt, &gm);
#endif
                char buf[32];
                std::strftime(buf, sizeof(buf), "%Y-%m-%dT%H:%M:%SZ", &gm);
                j << "{\"id\":" << id << ",\"date\":\"" << buf << "\"}";
            } while (a->NextRow());
        }
        j << "],";

        // Reputation
        j << "\"reputation\":[";
        {
            QueryResult rep = CharacterDatabase.PQuery(
                "SELECT faction, standing, flags FROM character_reputation WHERE guid={}", guid);
            bool first = true;
            if (rep) do
            {
                auto rr = rep->Fetch();
                if (!first) j << ",";
                first = false;
                j << "{\"faction_id\":" << rr[0].GetUInt16()
                  << ",\"standing\":" << rr[1].GetInt32()
                  << ",\"flags\":" << rr[2].GetUInt16() << "}";
            } while (rep->NextRow());
        }
        j << "],";

        // Skills
        j << "\"skills\":[";
        {
            QueryResult sk = CharacterDatabase.PQuery(
                "SELECT skill, value, max FROM character_skills WHERE guid={}", guid);
            bool first = true;
            if (sk) do
            {
                auto sr = sk->Fetch();
                if (!first) j << ",";
                first = false;
                j << "{\"skill_id\":" << sr[0].GetUInt32()
                  << ",\"value\":" << sr[1].GetUInt32()
                  << ",\"max\":" << sr[2].GetUInt32() << "}";
            } while (sk->NextRow());
        }
        j << "],";

        // Equipment (equipped slots 0-18) — optional, no enchants/gems.
        if (Config::Instance().ExportIncludeEquipment)
        {
            j << "\"equipment\":[";
            QueryResult eq = CharacterDatabase.PQuery(
                "SELECT ci.slot, ii.itemEntry FROM character_inventory ci "
                "JOIN item_instance ii ON ii.guid=ci.item "
                "WHERE ci.guid={} AND ci.bag=0 AND ci.slot<19 "
                "ORDER BY ci.slot", guid);
            bool first = true;
            if (eq) do
            {
                auto er = eq->Fetch();
                if (!first) j << ",";
                first = false;
                j << "{\"slot\":" << (int)er[0].GetUInt8()
                  << ",\"item_id\":" << er[1].GetUInt32() << "}";
            } while (eq->NextRow());
            j << "],";
        }

        // Titles: known titles are stored bit-packed in characters.knownTitles.
        // Emit as array of set bit indices.
        j << "\"titles\":[";
        {
            QueryResult tt = CharacterDatabase.PQuery(
                "SELECT knownTitles FROM characters WHERE guid={}", guid);
            bool first = true;
            if (tt)
            {
                auto ttr = tt->Fetch();
                std::string blob = ttr[0].GetString();
                // blob is space-separated hex or decimal ints depending on core; parse decimals.
                std::istringstream iss(blob);
                uint64_t word;
                int wordIdx = 0;
                while (iss >> word)
                {
                    for (int bit = 0; bit < 64; ++bit)
                    {
                        if (word & (uint64_t(1) << bit))
                        {
                            if (!first) j << ",";
                            first = false;
                            j << (wordIdx * 64 + bit);
                        }
                    }
                    wordIdx++;
                }
            }
        }
        j << "]";

        j << "}";
        return j.str();
    }

    // --- Header build ------------------------------------------------------
    static std::string BuildHeader(std::string const& fileId,
                                   std::string const& issuedAt,
                                   std::vector<uint8_t> const& salt,
                                   std::vector<uint8_t> const& iv,
                                   std::string const& serverPubKeyB64)
    {
        auto& cfg = Config::Instance();
        std::ostringstream j;
        j << "{"
          << "\"encryption\":{"
            << "\"algo\":\"AES-256-GCM\","
            << "\"iv\":\"" << Crypto::Base64Encode(iv) << "\","
            << "\"kdf\":\"argon2id\","
            << "\"kdf_memory_cost\":" << cfg.Argon2MemoryKB << ","
            << "\"kdf_parallelism\":" << cfg.Argon2Parallel << ","
            << "\"kdf_salt\":\"" << Crypto::Base64Encode(salt) << "\","
            << "\"kdf_time_cost\":" << cfg.Argon2TimeCost
          << "},"
          << "\"file_id\":\"" << fileId << "\","
          << "\"issued_at\":\"" << issuedAt << "\","
          << "\"source\":{"
            << "\"contact\":\"" << JsonEscape(cfg.ServerContact) << "\","
            << "\"core\":\"AzerothCore\","
            << "\"core_version\":\"master\","
            << "\"expansion\":\"" << cfg.ServerExpansion << "\","
            << "\"name\":\"" << JsonEscape(cfg.ServerName) << "\","
            << "\"pubkey\":\"" << serverPubKeyB64 << "\""
          << "},"
          << "\"wcpx\":\"1.0\""
          << "}";
        return j.str();
    }

    // Server public key: derive from private key on first use, cache.
    static std::string GetServerPubKeyB64()
    {
        static std::string cached;
        if (!cached.empty()) return cached;
        // Read the private key PEM, derive the raw pubkey via EVP.
        FILE* f = fopen(Config::Instance().ServerPrivateKeyPath.c_str(), "rb");
        if (!f) { TC_LOG_ERROR("module", "[WCPX] no private key"); return {}; }
        EVP_PKEY* pkey = PEM_read_PrivateKey(f, nullptr, nullptr, nullptr);
        fclose(f);
        if (!pkey) return {};
        std::vector<uint8_t> raw(32);
        size_t len = raw.size();
        if (EVP_PKEY_get_raw_public_key(pkey, raw.data(), &len) != 1 || len != 32)
        {
            EVP_PKEY_free(pkey);
            return {};
        }
        EVP_PKEY_free(pkey);
        cached = Crypto::Base64Encode(raw);
        return cached;
    }

    // --- Public entry point -----------------------------------------------
    ExportResult DoExport(ExportRequest const& req)
    {
        ExportResult res;

        if (req.characterGuid == 0 || req.passphrase.empty())
        { res.errorMessage = "invalid arguments"; return res; }

        // Resolve account
        QueryResult acc = CharacterDatabase.PQuery(
            "SELECT account FROM characters WHERE guid={}", req.characterGuid);
        if (!acc) { res.errorMessage = "character not found"; return res; }
        uint32_t accountId = acc->Fetch()[0].GetUInt32();

        if (!CheckExportQuota(accountId, req.bypassRateLimit))
        { res.errorMessage = "export quota exceeded (paid export required)"; return res; }

        std::string payloadJson;
        {
            std::string err;
            payloadJson = BuildPayload(req.characterGuid, err);
            if (payloadJson.empty()) { res.errorMessage = err; return res; }
        }
        std::string canonPayload = Codec::CanonicalizeJson(payloadJson);
        if (canonPayload.empty()) { res.errorMessage = "payload canonicalization failed"; return res; }

        // Crypto material
        auto salt = Crypto::RandomBytes(16);
        auto iv   = Crypto::RandomBytes(12);
        auto& cfg = Config::Instance();
        auto key = Crypto::DeriveKey(req.passphrase, salt,
                                     cfg.Argon2TimeCost, cfg.Argon2MemoryKB, cfg.Argon2Parallel);
        if (key.empty()) { res.errorMessage = "kdf failed"; return res; }

        std::vector<uint8_t> pt(canonPayload.begin(), canonPayload.end());
        std::vector<uint8_t> ct, tag;
        if (!Crypto::AeadEncrypt(key, iv, {}, pt, ct, tag))
        { res.errorMessage = "aead encrypt failed"; return res; }

        // Header (without signature yet)
        std::string fileId = UuidV4();
        std::string issuedAt = IsoUtcNow();
        std::string pubB64 = GetServerPubKeyB64();
        if (pubB64.empty()) { res.errorMessage = "cannot derive server pubkey"; return res; }

        std::string headerNoSig = BuildHeader(fileId, issuedAt, salt, iv, pubB64);
        std::string canonHeaderNoSig = Codec::CanonicalizeJson(headerNoSig);

        // sig_input = "wcpx-v1\n" + headerNoSig + "\n" + ct + tag
        std::vector<uint8_t> sigInput;
        static const char prefix[] = "wcpx-v1\n";
        sigInput.insert(sigInput.end(), prefix, prefix + sizeof(prefix) - 1);
        sigInput.insert(sigInput.end(), canonHeaderNoSig.begin(), canonHeaderNoSig.end());
        sigInput.push_back('\n');
        sigInput.insert(sigInput.end(), ct.begin(), ct.end());
        sigInput.insert(sigInput.end(), tag.begin(), tag.end());

        std::vector<uint8_t> sig;
        if (!Crypto::Sign(cfg.ServerPrivateKeyPath, sigInput, sig))
        { res.errorMessage = "sign failed"; return res; }

        // Add signature to header (canonical form comes out with correct key
        // order because we canonicalize the merged JSON).
        std::ostringstream withSig;
        // Strip trailing '}' from canonHeaderNoSig and inject signature key.
        std::string h = canonHeaderNoSig;
        h.pop_back(); // remove '}'
        withSig << h << ",\"signature\":{\"algo\":\"Ed25519\",\"value\":\""
                << Crypto::Base64Encode(sig) << "\"}}";
        std::string finalHeader = Codec::CanonicalizeJson(withSig.str());

        WcpxFile file;
        file.headerJson = finalHeader;
        file.payloadCiphertext = std::move(ct);
        file.payloadTag = std::move(tag);

        // Write to disk
        std::string outPath = cfg.ExportOutputDir + "/" + std::to_string(req.characterGuid) +
                              "-" + fileId.substr(0, 8) + ".wcpx";
        if (!Codec::WriteFile(outPath, file))
        { res.errorMessage = "write failed"; return res; }

        // Log usage
        CharacterDatabase.PExecute(
            "INSERT INTO wcpx_export_log (account_id, character_id, file_id, was_paid) "
            "VALUES ({}, {}, '{}', {})",
            accountId, req.characterGuid, fileId, req.bypassRateLimit ? 1 : 0);

        res.ok = true;
        res.fileId = fileId;
        res.filePath = outPath;
        TC_LOG_INFO("module", "[WCPX] exported char guid={} to {}", req.characterGuid, outPath);
        return res;
    }
}
