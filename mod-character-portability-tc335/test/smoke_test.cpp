/*
 * Standalone smoke test for the WCPX crypto + codec layers.
 *
 * Does NOT test DB-touching code (Config, Export, Import) — those need AC.
 * Verifies:
 *   1. CanonicalizeJson produces sorted-key, no-whitespace output
 *   2. WcpxFile binary roundtrip
 *   3. AES-256-GCM encrypt/decrypt roundtrip
 *   4. Argon2id KDF is deterministic
 *   5. Ed25519 sign/verify roundtrip (using a generated PEM keypair)
 *   6. Base64 encode/decode roundtrip
 *
 * Build:
 *   g++ -std=c++17 -O2 smoke_test.cpp \
 *       ../src/CharacterPortability_Crypto.cpp \
 *       ../src/CharacterPortability_Codec.cpp \
 *       -I../src -Istubs \
 *       -lssl -lcrypto -largon2 -o smoke_test
 *   ./smoke_test
 */
#include "CharacterPortability.h"

#include <cassert>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <string>
#include <vector>

using namespace WCPX;

namespace {

int g_tests_run = 0;
int g_tests_failed = 0;

#define TEST(name) static void name(); \
    struct name##_reg { name##_reg() { std::printf("[TEST] " #name "\n"); ++g_tests_run; \
        try { name(); std::printf("       OK\n"); } \
        catch (std::exception& e) { std::printf("       FAIL: %s\n", e.what()); ++g_tests_failed; } \
        catch (...) { std::printf("       FAIL (unknown)\n"); ++g_tests_failed; } } }; \
    static name##_reg name##_reg_i; \
    static void name()

#define ASSERT(cond) do { if (!(cond)) { throw std::runtime_error("assertion failed: " #cond); } } while (0)
#define ASSERT_EQ(a, b) do { if (!((a) == (b))) { throw std::runtime_error("expected equality failed: " #a " == " #b); } } while (0)

void GeneratePem(std::string const& path)
{
    // openssl genpkey -algorithm ED25519 -out path
    std::string cmd = "openssl genpkey -algorithm ED25519 -out " + path + " 2>/dev/null";
    int rc = std::system(cmd.c_str());
    if (rc != 0) throw std::runtime_error("openssl genpkey failed");
}

std::vector<uint8_t> RawPubFromPem(std::string const& pemPath)
{
    // Use openssl CLI to extract raw pubkey bytes.
    std::string outPath = pemPath + ".pubder";
    std::string cmd = "openssl pkey -in " + pemPath + " -pubout -outform DER -out " + outPath +
                      " 2>/dev/null";
    int rc = std::system(cmd.c_str());
    if (rc != 0) throw std::runtime_error("openssl pkey pubout failed");
    std::ifstream ifs(outPath, std::ios::binary);
    std::vector<uint8_t> der((std::istreambuf_iterator<char>(ifs)), {});
    std::remove(outPath.c_str());
    // Raw Ed25519 pubkey in a SubjectPublicKeyInfo DER is the last 32 bytes.
    if (der.size() < 32) throw std::runtime_error("der too small");
    return std::vector<uint8_t>(der.end() - 32, der.end());
}

} // anonymous

TEST(canonicalize_basic)
{
    // Simple two-key object; must be sorted.
    std::string in = "{\"b\":2,\"a\":1}";
    std::string canon = Codec::CanonicalizeJson(in);
    ASSERT_EQ(canon, "{\"a\":1,\"b\":2}");

    // Nested.
    in = "{\"z\":{\"y\":2,\"x\":1},\"a\":[3,2,1]}";
    canon = Codec::CanonicalizeJson(in);
    ASSERT_EQ(canon, "{\"a\":[3,2,1],\"z\":{\"x\":1,\"y\":2}}");
}

TEST(canonicalize_stable)
{
    // Repeated canonicalization is idempotent.
    std::string in = "{\"c\":3,\"a\":1,\"b\":2}";
    std::string once = Codec::CanonicalizeJson(in);
    std::string twice = Codec::CanonicalizeJson(once);
    ASSERT_EQ(once, twice);
}

TEST(base64_roundtrip)
{
    std::vector<uint8_t> data(64);
    for (size_t i = 0; i < data.size(); ++i) data[i] = static_cast<uint8_t>(i * 7);
    std::string b64 = Crypto::Base64Encode(data);
    std::vector<uint8_t> back;
    ASSERT(Crypto::Base64Decode(b64, back));
    ASSERT_EQ(data, back);
}

TEST(random_bytes)
{
    auto a = Crypto::RandomBytes(32);
    auto b = Crypto::RandomBytes(32);
    ASSERT_EQ(a.size(), (size_t)32);
    ASSERT_EQ(b.size(), (size_t)32);
    ASSERT(a != b);  // vanishingly-unlikely collision.
}

TEST(aead_roundtrip)
{
    auto key = Crypto::RandomBytes(32);
    auto iv  = Crypto::RandomBytes(12);
    std::string message = "hello WCPX";
    std::vector<uint8_t> pt(message.begin(), message.end());
    std::vector<uint8_t> ct, tag;
    ASSERT(Crypto::AeadEncrypt(key, iv, {}, pt, ct, tag));
    ASSERT_EQ(tag.size(), (size_t)16);
    std::vector<uint8_t> back;
    ASSERT(Crypto::AeadDecrypt(key, iv, {}, ct, tag, back));
    ASSERT_EQ(pt, back);
}

TEST(aead_tampered_ct_fails)
{
    auto key = Crypto::RandomBytes(32);
    auto iv  = Crypto::RandomBytes(12);
    std::vector<uint8_t> pt = {1,2,3,4,5,6,7,8};
    std::vector<uint8_t> ct, tag;
    ASSERT(Crypto::AeadEncrypt(key, iv, {}, pt, ct, tag));
    ct[0] ^= 0x01;
    std::vector<uint8_t> back;
    ASSERT(!Crypto::AeadDecrypt(key, iv, {}, ct, tag, back));
}

TEST(argon2_deterministic)
{
    std::vector<uint8_t> salt(16, 0x42);
    auto k1 = Crypto::DeriveKey("hunter2", salt, 2, 8192, 1);
    auto k2 = Crypto::DeriveKey("hunter2", salt, 2, 8192, 1);
    ASSERT_EQ(k1, k2);
    ASSERT_EQ(k1.size(), (size_t)32);
    auto k3 = Crypto::DeriveKey("hunter3", salt, 2, 8192, 1);
    ASSERT(k1 != k3);
}

TEST(ed25519_sign_verify)
{
    const std::string pem = "/tmp/wcpx_test_key.pem";
    GeneratePem(pem);
    auto pubRaw = RawPubFromPem(pem);
    ASSERT_EQ(pubRaw.size(), (size_t)32);

    std::vector<uint8_t> msg = {'h','e','l','l','o'};
    std::vector<uint8_t> sig;
    ASSERT(Crypto::Sign(pem, msg, sig));
    ASSERT_EQ(sig.size(), (size_t)64);
    ASSERT(Crypto::Verify(pubRaw, msg, sig));

    // Tamper message.
    msg[0] ^= 0x01;
    ASSERT(!Crypto::Verify(pubRaw, msg, sig));

    std::remove(pem.c_str());
}

TEST(wcpx_file_binary_roundtrip)
{
    WcpxFile f;
    f.headerJson = "{\"a\":1,\"b\":\"hello\"}";
    f.payloadCiphertext = {0xde, 0xad, 0xbe, 0xef, 0x00, 0x11, 0x22, 0x33};
    f.payloadTag.assign(16, 0xAA);

    const std::string path = "/tmp/wcpx_test.wcpx";
    ASSERT(Codec::WriteFile(path, f));

    WcpxFile g;
    std::string err;
    ASSERT(Codec::ReadFile(path, g, err));
    ASSERT_EQ(g.headerJson, f.headerJson);
    ASSERT_EQ(g.payloadCiphertext, f.payloadCiphertext);
    ASSERT_EQ(g.payloadTag, f.payloadTag);
    std::remove(path.c_str());
}

TEST(bad_magic_rejected)
{
    // Manually create garbage file.
    std::ofstream ofs("/tmp/wcpx_bad.wcpx", std::ios::binary);
    const char garbage[] = "NOTWCPXBLAH";
    ofs.write(garbage, sizeof(garbage) - 1);
    ofs.close();
    WcpxFile out;
    std::string err;
    ASSERT(!Codec::ReadFile("/tmp/wcpx_bad.wcpx", out, err));
    ASSERT(err.find("magic") != std::string::npos);
    std::remove("/tmp/wcpx_bad.wcpx");
}

int main()
{
    // Registers auto-run via static ctors of TEST(). Just report.
    std::printf("\n%d tests run, %d failed\n", g_tests_run, g_tests_failed);
    return g_tests_failed == 0 ? 0 : 1;
}
