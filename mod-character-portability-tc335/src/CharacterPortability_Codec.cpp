/*
 * WCPX-1.0 file codec (SPEC §4).
 *
 * Binary layout:
 *   MAGIC(4)  = "WCPX"
 *   VERSION(2, u16 BE) = 1
 *   FLAGS(1)  = 0
 *   HEADER_LEN(2, u16 BE)
 *   HEADER_JSON(HEADER_LEN bytes, UTF-8 canonical)
 *   PAYLOAD_LEN(4, u32 BE)
 *   PAYLOAD_CT(PAYLOAD_LEN bytes)
 *   PAYLOAD_TAG(16 bytes)
 */
#include "CharacterPortability.h"

#include <filesystem>
#include <fstream>
#include <sstream>
#include <cstring>
#include <algorithm>

// Minimal JSON canonicalizer using a small hand-written parser.
// AzerothCore already ships nlohmann/json via its own deps in most builds; if
// unavailable in your fork, drop-in the single-header nlohmann/json.hpp and
// swap the CanonicalizeJson body for `json::parse(s).dump()` with a
// key-sorting Object using ordered_json.
//
// For the reference implementation we ship this minimal version to avoid a
// hard dep. It only supports the subset actually emitted by our exporter
// (no comments, no NaN, no trailing commas).
#include <cctype>
#include <map>

namespace {

struct Parser
{
    std::string const& s;
    size_t i = 0;
    std::ostringstream out;

    explicit Parser(std::string const& in) : s(in) {}

    void skipWs() { while (i < s.size() && std::isspace((unsigned char)s[i])) ++i; }
    bool eof() const { return i >= s.size(); }

    bool parseValue()
    {
        skipWs();
        if (eof()) return false;
        char c = s[i];
        if (c == '{') return parseObject();
        if (c == '[') return parseArray();
        if (c == '"') return parseString();
        if (c == 't' || c == 'f') return parseBool();
        if (c == 'n') return parseNull();
        return parseNumber();
    }

    bool parseObject()
    {
        ++i; // {
        std::map<std::string, std::string> entries;
        skipWs();
        if (i < s.size() && s[i] == '}') { ++i; out << "{}"; return true; }
        while (true)
        {
            skipWs();
            if (i >= s.size() || s[i] != '"') return false;
            std::ostringstream keyStream;
            {
                std::ostringstream saved;
                saved.swap(out);
                if (!parseString()) return false;
                keyStream.str(out.str());
                out.swap(saved);
            }
            std::string key = keyStream.str();
            skipWs();
            if (i >= s.size() || s[i] != ':') return false;
            ++i;
            std::ostringstream valStream;
            {
                std::ostringstream saved;
                saved.swap(out);
                if (!parseValue()) return false;
                valStream.str(out.str());
                out.swap(saved);
            }
            entries[key] = valStream.str();
            skipWs();
            if (i < s.size() && s[i] == ',') { ++i; continue; }
            if (i < s.size() && s[i] == '}') { ++i; break; }
            return false;
        }
        out << '{';
        bool first = true;
        for (auto const& kv : entries)
        {
            if (!first) out << ',';
            first = false;
            out << kv.first << ':' << kv.second;
        }
        out << '}';
        return true;
    }

    bool parseArray()
    {
        ++i; // [
        out << '[';
        skipWs();
        if (i < s.size() && s[i] == ']') { ++i; out << ']'; return true; }
        bool first = true;
        while (true)
        {
            if (!first) out << ',';
            first = false;
            if (!parseValue()) return false;
            skipWs();
            if (i < s.size() && s[i] == ',') { ++i; continue; }
            if (i < s.size() && s[i] == ']') { ++i; break; }
            return false;
        }
        out << ']';
        return true;
    }

    bool parseString()
    {
        if (i >= s.size() || s[i] != '"') return false;
        size_t start = i++;
        while (i < s.size() && s[i] != '"')
        {
            if (s[i] == '\\' && i + 1 < s.size()) i += 2;
            else ++i;
        }
        if (i >= s.size()) return false;
        ++i;
        out << s.substr(start, i - start);
        return true;
    }

    bool parseBool()
    {
        if (s.compare(i, 4, "true") == 0) { out << "true"; i += 4; return true; }
        if (s.compare(i, 5, "false") == 0) { out << "false"; i += 5; return true; }
        return false;
    }
    bool parseNull()
    {
        if (s.compare(i, 4, "null") == 0) { out << "null"; i += 4; return true; }
        return false;
    }
    bool parseNumber()
    {
        size_t start = i;
        if (s[i] == '-') ++i;
        while (i < s.size() && (std::isdigit((unsigned char)s[i]) ||
               s[i] == '.' || s[i] == 'e' || s[i] == 'E' || s[i] == '+' || s[i] == '-'))
            ++i;
        if (i == start) return false;
        out << s.substr(start, i - start);
        return true;
    }
};

// Big-endian u16/u32 read/write helpers.
void putU16(std::vector<uint8_t>& v, uint16_t x) { v.push_back(x >> 8); v.push_back(x & 0xff); }
void putU32(std::vector<uint8_t>& v, uint32_t x) {
    v.push_back((x >> 24) & 0xff); v.push_back((x >> 16) & 0xff);
    v.push_back((x >> 8) & 0xff); v.push_back(x & 0xff);
}
uint16_t getU16(uint8_t const* p) { return (uint16_t(p[0]) << 8) | p[1]; }
uint32_t getU32(uint8_t const* p) {
    return (uint32_t(p[0]) << 24) | (uint32_t(p[1]) << 16) |
           (uint32_t(p[2]) << 8) | uint32_t(p[3]);
}

} // anonymous

namespace WCPX::Codec
{
    std::string CanonicalizeJson(std::string const& json)
    {
        Parser p(json);
        if (!p.parseValue()) return "";
        return p.out.str();
    }

    bool WriteFile(std::string const& path, WcpxFile const& file)
    {
        std::vector<uint8_t> buf;
        buf.reserve(file.headerJson.size() + file.payloadCiphertext.size() + 64);
        // magic + version + flags
        buf.push_back('W'); buf.push_back('C'); buf.push_back('P'); buf.push_back('X');
        putU16(buf, 1);
        buf.push_back(0);
        if (file.headerJson.size() > 65535) return false;
        putU16(buf, static_cast<uint16_t>(file.headerJson.size()));
        buf.insert(buf.end(), file.headerJson.begin(), file.headerJson.end());
        putU32(buf, static_cast<uint32_t>(file.payloadCiphertext.size()));
        buf.insert(buf.end(), file.payloadCiphertext.begin(), file.payloadCiphertext.end());
        if (file.payloadTag.size() != 16) return false;
        buf.insert(buf.end(), file.payloadTag.begin(), file.payloadTag.end());

        std::error_code ec;
        auto parent = std::filesystem::path(path).parent_path();
        if (!parent.empty())
            std::filesystem::create_directories(parent, ec);
        std::ofstream ofs(path, std::ios::binary | std::ios::trunc);
        if (!ofs) return false;
        ofs.write(reinterpret_cast<const char*>(buf.data()),
                  static_cast<std::streamsize>(buf.size()));
        return static_cast<bool>(ofs);
    }

    bool ReadFile(std::string const& path, WcpxFile& out, std::string& err)
    {
        std::ifstream ifs(path, std::ios::binary);
        if (!ifs) { err = "cannot open file"; return false; }
        std::vector<uint8_t> buf((std::istreambuf_iterator<char>(ifs)), {});
        return ReadBytes(buf, out, err);
    }

    // ReadBytes lives here too (forward-decl in header alt: extend struct).
    bool ReadBytes(std::vector<uint8_t> const& buf, WcpxFile& out, std::string& err)
    {
        size_t p = 0;
        if (buf.size() < 9) { err = "truncated header"; return false; }
        if (std::memcmp(buf.data(), "WCPX", 4) != 0) { err = "bad magic"; return false; }
        p += 4;
        uint16_t ver = getU16(&buf[p]); p += 2;
        if (ver != 1) { err = "unsupported version"; return false; }
        p += 1; // flags
        uint16_t hlen = getU16(&buf[p]); p += 2;
        if (p + hlen + 4 > buf.size()) { err = "truncated payload"; return false; }
        out.headerJson.assign(reinterpret_cast<const char*>(&buf[p]), hlen);
        p += hlen;
        uint32_t plen = getU32(&buf[p]); p += 4;
        if (p + plen + 16 > buf.size()) { err = "truncated ct+tag"; return false; }
        out.payloadCiphertext.assign(&buf[p], &buf[p + plen]);
        p += plen;
        out.payloadTag.assign(&buf[p], &buf[p + 16]);
        return true;
    }
}
