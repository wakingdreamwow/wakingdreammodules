/*
 * WCPX HTTP API server (SPEC §12).
 *
 * Uses cpp-httplib (vendored under third_party/) — header-only, MIT-licensed.
 * Runs in a background thread; safe to enable/disable via config.
 *
 * Endpoints (all under /wcpx/v1):
 *   GET  /status                     public metadata + pubkey
 *   POST /export                     JSON body -> binary .wcpx response
 *   POST /import                     multipart -> JSON {new_character_id,...}
 *   GET  /trust/pending              admin: list TOFU-pending pubkeys
 *   POST /trust/approve              admin: promote a pubkey to whitelist
 *
 * Auth: `Authorization: Bearer <token>` — token from config; empty token
 *       disables the server entirely.
 * Bind: 127.0.0.1 by default; DO NOT expose to public internet.
 */
#include "CharacterPortability.h"

#include "DatabaseEnv.h"
#include "QueryResult.h"
#include "Field.h"
#include "Log.h"

#include <openssl/pem.h>
#include <openssl/evp.h>

#include "third_party/httplib.h"

#include <atomic>
#include <memory>
#include <thread>
#include <sstream>

namespace WCPX
{
    namespace {

    std::unique_ptr<httplib::Server> g_server;
    std::thread g_thread;
    std::atomic<bool> g_running{false};

    // ---- Server pubkey (base64) — derived once from PEM ------------------
    std::string ServerPubKeyB64()
    {
        static std::string cached;
        if (!cached.empty()) return cached;
        FILE* f = fopen(Config::Instance().ServerPrivateKeyPath.c_str(), "rb");
        if (!f) return {};
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

    bool CheckAuth(httplib::Request const& req)
    {
        auto const& want = Config::Instance().HttpBearerToken;
        if (want.empty()) return false;
        auto got = req.get_header_value("Authorization");
        std::string prefix = "Bearer ";
        if (got.rfind(prefix, 0) != 0) return false;
        std::string token = got.substr(prefix.size());
        // Constant-time comparison via memcmp on equal-length inputs.
        if (token.size() != want.size()) return false;
        volatile unsigned char diff = 0;
        for (size_t i = 0; i < token.size(); ++i)
            diff |= static_cast<unsigned char>(token[i] ^ want[i]);
        return diff == 0;
    }

    void JsonError(httplib::Response& res, int status, std::string const& code,
                   std::string const& msg = "")
    {
        res.status = status;
        std::ostringstream j;
        j << "{\"error\":\"" << code << "\"";
        if (!msg.empty()) j << ",\"message\":\"" << msg << "\"";
        j << "}";
        res.set_content(j.str(), "application/json");
    }

    // ---- Handlers ---------------------------------------------------------
    void HandleStatus(httplib::Request const&, httplib::Response& res)
    {
        auto& cfg = Config::Instance();
        std::ostringstream j;
        j << "{"
          << "\"wcpx\":\"1.0\","
          << "\"server_name\":\"" << cfg.ServerName << "\","
          << "\"server_core\":\"AzerothCore\","
          << "\"core_version\":\"master\","
          << "\"pubkey\":\"" << ServerPubKeyB64() << "\","
          << "\"features\":{"
            << "\"export\":true,"
            << "\"import\":true,"
            << "\"trust_modes\":[\"whitelist\",\"tofu\"]"
          << "}"
          << "}";
        res.set_content(j.str(), "application/json");
    }

    // Naive JSON field extractor — matches "key":<value> for primitive types.
    // We use this instead of pulling a full JSON lib. Sufficient for our
    // small request bodies.
    bool JsonField(std::string const& body, std::string const& key, std::string& out)
    {
        std::string needle = "\"" + key + "\"";
        auto p = body.find(needle);
        if (p == std::string::npos) return false;
        p = body.find(':', p);
        if (p == std::string::npos) return false;
        p++;
        while (p < body.size() && std::isspace((unsigned char)body[p])) p++;
        if (p >= body.size()) return false;
        if (body[p] == '"')
        {
            auto q = body.find('"', p + 1);
            if (q == std::string::npos) return false;
            out = body.substr(p + 1, q - p - 1);
            return true;
        }
        auto q = p;
        while (q < body.size() && (std::isdigit((unsigned char)body[q]) ||
                                    body[q] == '-' || body[q] == '.' ||
                                    body[q] == 't' || body[q] == 'r' ||
                                    body[q] == 'u' || body[q] == 'e' ||
                                    body[q] == 'f' || body[q] == 'a' ||
                                    body[q] == 'l' || body[q] == 's')) q++;
        out = body.substr(p, q - p);
        return true;
    }

    void HandleExport(httplib::Request const& req, httplib::Response& res)
    {
        std::string s_char, s_pass, s_bypass;
        if (!JsonField(req.body, "character_id", s_char) ||
            !JsonField(req.body, "passphrase",   s_pass))
        {
            JsonError(res, 400, "bad_request", "missing character_id or passphrase");
            return;
        }
        JsonField(req.body, "bypass_quota", s_bypass);

        ExportRequest ereq;
        ereq.characterGuid = static_cast<uint32_t>(std::stoul(s_char));
        ereq.passphrase = s_pass;
        ereq.bypassRateLimit = (s_bypass == "true" || s_bypass == "1");

        auto r = DoExport(ereq);
        if (!r.ok)
        {
            if (r.errorMessage.find("quota") != std::string::npos)
                JsonError(res, 402, "quota_exceeded", r.errorMessage);
            else if (r.errorMessage.find("not found") != std::string::npos)
                JsonError(res, 404, "not_found", r.errorMessage);
            else
                JsonError(res, 500, "export_failed", r.errorMessage);
            return;
        }

        // Read the file bytes and return them.
        std::ifstream ifs(r.filePath, std::ios::binary);
        std::string bytes((std::istreambuf_iterator<char>(ifs)), {});
        res.set_content(bytes, "application/x.wcpx");
        res.set_header("Content-Disposition",
            "attachment; filename=\"" + r.fileId.substr(0, 8) + ".wcpx\"");
    }

    void HandleImport(httplib::Request const& req, httplib::Response& res)
    {
        auto fileField = req.get_file_value("file");
        if (fileField.content.empty())
        {
            JsonError(res, 400, "bad_request", "missing 'file'");
            return;
        }
        std::string passphrase = req.get_file_value("passphrase").content;
        std::string targetAccStr = req.get_file_value("target_account_id").content;
        std::string paidToken = req.get_file_value("paid_token").content;

        auto& cfg = Config::Instance();
        if (cfg.ImportRequireToken && paidToken.empty())
        {
            JsonError(res, 402, "payment_required", "paid_token missing");
            return;
        }
        if (passphrase.empty() || targetAccStr.empty())
        {
            JsonError(res, 400, "bad_request", "missing passphrase or target_account_id");
            return;
        }

        ImportRequest ireq;
        ireq.bytes.assign(fileField.content.begin(), fileField.content.end());
        ireq.passphrase = passphrase;
        ireq.targetAccountId = static_cast<uint32_t>(std::stoul(targetAccStr));
        ireq.bypassPaidToken = false;

        auto r = DoImport(ireq);
        if (!r.ok)
        {
            int status = 400;
            std::string code = "import_failed";
            if (r.errorMessage.find("already imported") != std::string::npos)
                { status = 409; code = "replay"; }
            else if (r.errorMessage.find("trusted") != std::string::npos)
                { status = 403; code = "untrusted"; }
            else if (r.errorMessage.find("passphrase") != std::string::npos)
                { status = 400; code = "wrong_passphrase"; }
            JsonError(res, status, code, r.errorMessage);
            return;
        }

        std::ostringstream j;
        j << "{"
          << "\"ok\":true,"
          << "\"new_character_id\":" << r.newCharacterGuid
          << "}";
        res.set_content(j.str(), "application/json");
    }

    void HandlePreview(httplib::Request const& req, httplib::Response& res)
    {
        auto fileField = req.get_file_value("file");
        if (fileField.content.empty())
        { JsonError(res, 400, "bad_request", "missing 'file'"); return; }
        std::string passphrase = req.get_file_value("passphrase").content;
        if (passphrase.empty())
        { JsonError(res, 400, "bad_request", "missing passphrase"); return; }

        PreviewRequest preq;
        preq.bytes.assign(fileField.content.begin(), fileField.content.end());
        preq.passphrase = passphrase;
        auto r = DoPreview(preq);
        if (!r.ok)
        {
            int status = 400;
            std::string code = "preview_failed";
            if (r.errorMessage.find("passphrase") != std::string::npos)
                { status = 400; code = "wrong_passphrase"; }
            else if (r.errorMessage.find("signature") != std::string::npos)
                { status = 400; code = "bad_signature"; }
            JsonError(res, status, code, r.errorMessage);
            return;
        }

        // JSON string escape helper
        auto esc = [](std::string const& s) -> std::string {
            std::string out;
            for (char c : s) {
                if (c == '"') out += "\\\"";
                else if (c == '\\') out += "\\\\";
                else if (c == '\n') out += "\\n";
                else out += c;
            }
            return out;
        };

        std::ostringstream j;
        j << "{"
          << "\"ok\":true,"
          << "\"file_id\":\"" << esc(r.fileId) << "\","
          << "\"issued_at\":\"" << esc(r.issuedAt) << "\","
          << "\"source_name\":\"" << esc(r.sourceName) << "\","
          << "\"source_core\":\"" << esc(r.sourceCore) << "\","
          << "\"source_pubkey\":\"" << esc(r.sourcePubkey) << "\","
          << "\"source_trusted\":" << (r.sourceTrusted ? "true" : "false") << ","
          << "\"already_imported\":" << (r.alreadyImported ? "true" : "false") << ","
          << "\"character\":{"
            << "\"name\":\"" << esc(r.charName) << "\","
            << "\"race\":" << r.race << ","
            << "\"class\":" << r.cls << ","
            << "\"gender\":" << r.gender << ","
            << "\"level\":" << r.level << ","
            << "\"faction\":\"" << esc(r.faction) << "\""
          << "},"
          << "\"counts\":{"
            << "\"spells\":"       << r.spellCount << ","
            << "\"achievements\":" << r.achievementCount << ","
            << "\"talents\":"      << r.talentCount << ","
            << "\"reputation\":"   << r.reputationCount << ","
            << "\"skills\":"       << r.skillCount << ","
            << "\"titles\":"       << r.titleCount
          << "},"
          << "\"equipment\":[";
        bool first = true;
        for (auto const& e : r.equipment)
        {
            if (!first) j << ",";
            first = false;
            j << "{\"slot\":" << e.slot
              << ",\"item_id\":" << e.itemId
              << ",\"item_name\":\"" << esc(e.itemName) << "\"}";
        }
        j << "],"
          << "\"mounts\":[";
        first = true;
        for (auto const& m : r.mounts)
        {
            if (!first) j << ",";
            first = false;
            j << "{\"spell_id\":" << m.spellId
              << ",\"spell_name\":\"" << esc(m.spellName) << "\""
              << ",\"icon_name\":\"" << esc(m.iconName) << "\"}";
        }
        j << "],"
          << "\"warnings\":[";
        first = true;
        for (auto const& w : r.warnings)
        {
            if (!first) j << ",";
            first = false;
            j << "\"" << esc(w) << "\"";
        }
        j << "]}";
        res.set_content(j.str(), "application/json");
    }

    void HandleTrustPending(httplib::Request const&, httplib::Response& res)
    {
        QueryResult q = CharacterDatabase.Query(
            "SELECT source_pubkey, source_name, source_core, source_contact, "
            "       first_seen, seen_count "
            "FROM wcpx_pending_pubkeys ORDER BY first_seen DESC");
        std::ostringstream j;
        j << "{\"pending\":[";
        bool first = true;
        if (q) do
        {
            auto row = q->Fetch();
            if (!first) j << ",";
            first = false;
            j << "{"
              << "\"pubkey\":\""       << row[0].Get<std::string>() << "\","
              << "\"source_name\":\""  << row[1].Get<std::string>() << "\","
              << "\"source_core\":\""  << row[2].Get<std::string>() << "\","
              << "\"source_contact\":\"" << row[3].Get<std::string>() << "\","
              << "\"first_seen\":\""   << row[4].Get<std::string>() << "\","
              << "\"seen_count\":"     << row[5].Get<uint32_t>()
              << "}";
        } while (q->NextRow());
        j << "]}";
        res.set_content(j.str(), "application/json");
    }

    void HandleTrustApprove(httplib::Request const& req, httplib::Response& res)
    {
        std::string pubkey;
        if (!JsonField(req.body, "pubkey", pubkey) || pubkey.empty())
        {
            JsonError(res, 400, "bad_request", "missing pubkey");
            return;
        }
        Config::Instance().TrustWhitelist.push_back(pubkey);
        CharacterDatabase.Execute(
            "DELETE FROM wcpx_pending_pubkeys WHERE source_pubkey='{}'", pubkey);
        std::ostringstream j;
        j << "{\"ok\":true,\"persist_hint\":"
          << "\"add this pubkey to CharacterPortability.Trust.Whitelist\"}";
        res.set_content(j.str(), "application/json");
    }

    } // anonymous

    void StartHttpServer()
    {
        auto& cfg = Config::Instance();
        if (!cfg.HttpEnabled || cfg.HttpBearerToken.empty())
        {
            LOG_INFO("module", "[WCPX] HTTP API disabled");
            return;
        }

        g_server = std::make_unique<httplib::Server>();

        // Middleware: auth check before handlers (except /status which is
        // public metadata, useful for CMS health checks).
        auto authWrap = [](httplib::Server::Handler handler)
        {
            return [handler](httplib::Request const& req, httplib::Response& res)
            {
                if (!CheckAuth(req))
                {
                    JsonError(res, 401, "unauthorized");
                    return;
                }
                handler(req, res);
            };
        };

        g_server->Get ("/wcpx/v1/status",         HandleStatus);
        g_server->Post("/wcpx/v1/export",         authWrap(HandleExport));
        g_server->Post("/wcpx/v1/preview",        authWrap(HandlePreview));
        g_server->Post("/wcpx/v1/import",         authWrap(HandleImport));
        g_server->Get ("/wcpx/v1/trust/pending",  authWrap(HandleTrustPending));
        g_server->Post("/wcpx/v1/trust/approve",  authWrap(HandleTrustApprove));

        g_running = true;
        g_thread = std::thread([host = cfg.HttpBindHost, port = cfg.HttpBindPort]()
        {
            LOG_INFO("module", "[WCPX] HTTP API listening on {}:{}", host, port);
            g_server->listen(host, port);
            LOG_INFO("module", "[WCPX] HTTP API stopped");
            g_running = false;
        });
    }

    void StopHttpServer()
    {
        if (g_server) g_server->stop();
        if (g_thread.joinable()) g_thread.join();
        g_server.reset();
    }
}
