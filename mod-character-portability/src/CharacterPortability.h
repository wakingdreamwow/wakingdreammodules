/*
 * mod-character-portability — WCPX-1.0 reference implementation for AzerothCore.
 * https://github.com/wakingdreamwow/wcpx-spec
 *
 * License: MIT
 */
#ifndef WCPX_CHARACTER_PORTABILITY_H
#define WCPX_CHARACTER_PORTABILITY_H

#include <string>
#include <vector>
#include <cstdint>
#include <optional>

namespace WCPX
{
    // ------------------------------------------------------------------------
    // Config (populated at worldserver load from character_portability.conf)
    // ------------------------------------------------------------------------
    struct Config
    {
        // Server identity
        std::string ServerPrivateKeyPath;
        std::string ServerName;
        std::string ServerContact;
        std::string ServerExpansion;

        // Trust
        std::string TrustMode;          // "whitelist" | "tofu" | "open"
        std::vector<std::string> TrustWhitelist;  // base64 pubkeys
        std::string TofuQueuePath;

        // Rate limit / gating
        uint32_t ExportFreePerMonth = 1;
        bool ImportRequireToken = true;
        std::string ExportOutputDir = "wcpx-exports";

        // HTTP API (§12 Integration API)
        bool HttpEnabled = false;
        std::string HttpBindHost = "127.0.0.1";
        uint16_t HttpBindPort = 7879;
        std::string HttpBearerToken;      // if empty, HTTP starts disabled

        // Import policy
        uint32_t ImportMaxAgeDays = 0;
        bool ImportRejectOverLevel = false;

        // Equipment carry-over (equipped slots only, no enchants/gems)
        bool ExportIncludeEquipment = true;
        bool ImportAcceptEquipment  = true;

        // Argon2id
        uint32_t Argon2TimeCost   = 3;
        uint32_t Argon2MemoryKB   = 65536;
        uint32_t Argon2Parallel   = 4;

        static Config& Instance();
        void Load();
    };

    // ------------------------------------------------------------------------
    // Crypto primitives — thin OpenSSL / libargon2 wrappers.
    // ------------------------------------------------------------------------
    namespace Crypto
    {
        // 32 raw bytes.
        using SymmetricKey = std::vector<uint8_t>;

        // Derive AES-256 key from passphrase + salt using Argon2id.
        SymmetricKey DeriveKey(std::string const& passphrase,
                               std::vector<uint8_t> const& salt,
                               uint32_t timeCost, uint32_t memoryKB,
                               uint32_t parallelism);

        // AES-256-GCM encrypt/decrypt. iv MUST be 12 bytes.
        // On encrypt, tag is 16 bytes appended.
        bool AeadEncrypt(SymmetricKey const& key,
                         std::vector<uint8_t> const& iv,
                         std::vector<uint8_t> const& aad,
                         std::vector<uint8_t> const& plaintext,
                         std::vector<uint8_t>& ciphertextOut,
                         std::vector<uint8_t>& tagOut);

        bool AeadDecrypt(SymmetricKey const& key,
                         std::vector<uint8_t> const& iv,
                         std::vector<uint8_t> const& aad,
                         std::vector<uint8_t> const& ciphertext,
                         std::vector<uint8_t> const& tag,
                         std::vector<uint8_t>& plaintextOut);

        // Ed25519.
        bool Sign(std::string const& privateKeyPemPath,
                  std::vector<uint8_t> const& message,
                  std::vector<uint8_t>& signatureOut);

        // pubkey: 32 raw bytes (base64-decoded from header)
        bool Verify(std::vector<uint8_t> const& pubKey,
                    std::vector<uint8_t> const& message,
                    std::vector<uint8_t> const& signature);

        // Random N bytes via OpenSSL RAND_bytes.
        std::vector<uint8_t> RandomBytes(size_t n);

        // base64 (standard, with padding).
        std::string Base64Encode(std::vector<uint8_t> const& in);
        bool Base64Decode(std::string const& in, std::vector<uint8_t>& out);
    }

    // ------------------------------------------------------------------------
    // Codec — reads and writes .wcpx binary container per SPEC §4.
    // ------------------------------------------------------------------------
    struct WcpxFile
    {
        std::string headerJson;                 // canonical JSON with signature
        std::vector<uint8_t> payloadCiphertext;
        std::vector<uint8_t> payloadTag;        // 16 bytes
    };

    namespace Codec
    {
        // Write .wcpx bytes to disk.
        bool WriteFile(std::string const& path, WcpxFile const& file);

        // Read + parse the outer container. Does NOT verify signature or
        // decrypt payload — those are separate steps.
        bool ReadFile(std::string const& path, WcpxFile& out, std::string& errorOut);
        bool ReadBytes(std::vector<uint8_t> const& buf, WcpxFile& out, std::string& errorOut);

        // Canonical JSON (sorted keys, no whitespace).
        std::string CanonicalizeJson(std::string const& json);
    }

    // ------------------------------------------------------------------------
    // Export — build a WcpxFile for a given character.
    // ------------------------------------------------------------------------
    struct ExportRequest
    {
        uint32_t characterGuid = 0;
        std::string passphrase;
        bool bypassRateLimit = false;        // true for GM command
    };
    struct ExportResult
    {
        bool ok = false;
        std::string errorMessage;
        std::string filePath;                // when written to disk
        std::vector<uint8_t> bytes;          // when returned to caller (web API)
        std::string fileId;
    };
    ExportResult DoExport(ExportRequest const& req);

    // ------------------------------------------------------------------------
    // Import — accept a WcpxFile as a new character on this server.
    // ------------------------------------------------------------------------
    struct ImportRequest
    {
        std::string filePath;                // OR bytes below
        std::vector<uint8_t> bytes;
        std::string passphrase;
        uint32_t targetAccountId = 0;
        bool bypassPaidToken = false;        // true for GM command
    };
    struct ImportResult
    {
        bool ok = false;
        std::string errorMessage;
        uint32_t newCharacterGuid = 0;
    };
    ImportResult DoImport(ImportRequest const& req);

    // ------------------------------------------------------------------------
    // Preview — decrypt + verify + return a summary WITHOUT creating a char
    // or consuming the replay ledger. Used by CMS UI to show "here's what
    // you're about to import" before payment.
    // ------------------------------------------------------------------------
    struct PreviewRequest
    {
        std::string filePath;
        std::vector<uint8_t> bytes;
        std::string passphrase;
    };
    struct PreviewEquipItem
    {
        uint32_t slot = 0;
        uint32_t itemId = 0;
        std::string itemName;   // empty if unknown on this server
    };
    struct PreviewResult
    {
        bool ok = false;
        std::string errorMessage;
        // Header metadata
        std::string fileId;
        std::string sourceName;
        std::string sourceCore;
        std::string sourcePubkey;
        std::string issuedAt;
        bool alreadyImported = false;  // replay-check hint
        bool sourceTrusted = false;
        // Character summary
        std::string charName;
        uint32_t race = 0, cls = 0, gender = 0, level = 0;
        std::string faction;
        // Content counts
        uint32_t spellCount = 0, achievementCount = 0, talentCount = 0;
        uint32_t reputationCount = 0, skillCount = 0, titleCount = 0;
        // Equipment (slot + itemId + itemName lookup)
        std::vector<PreviewEquipItem> equipment;
        // Non-fatal warnings the CMS should surface
        std::vector<std::string> warnings;
    };
    PreviewResult DoPreview(PreviewRequest const& req);

    // ------------------------------------------------------------------------
    // GM command registration entry point (called by loader).
    // ------------------------------------------------------------------------
    void RegisterChatCommands();

    // ------------------------------------------------------------------------
    // HTTP server lifecycle (§12). No-op if HttpEnabled=false or token empty.
    // ------------------------------------------------------------------------
    void StartHttpServer();
    void StopHttpServer();
}

// AC static-loader entry point (referenced by mod-character-portability_loader.cpp)
void Addmod_character_portabilityScripts();

#endif // WCPX_CHARACTER_PORTABILITY_H
