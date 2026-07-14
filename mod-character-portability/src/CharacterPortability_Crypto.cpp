/*
 * WCPX crypto layer.
 *
 * Dependencies:
 *   - OpenSSL 1.1.1+  (Ed25519, AES-256-GCM, RAND, base64)
 *   - libargon2       (Argon2id KDF)
 *
 * Add to your worldserver CMakeLists.txt when integrating this module:
 *   find_package(argon2 REQUIRED)
 *   target_link_libraries(worldserver PRIVATE argon2)
 */
#include "CharacterPortability.h"
#include "Log.h"

#include <openssl/evp.h>
#include <openssl/pem.h>
#include <openssl/rand.h>
#include <openssl/bio.h>
#include <openssl/buffer.h>

#include <argon2.h>

#include <cstring>

namespace WCPX::Crypto
{
    std::vector<uint8_t> RandomBytes(size_t n)
    {
        std::vector<uint8_t> out(n);
        if (RAND_bytes(out.data(), static_cast<int>(n)) != 1)
        {
            LOG_ERROR("module", "[WCPX] RAND_bytes failed");
            return {};
        }
        return out;
    }

    std::string Base64Encode(std::vector<uint8_t> const& in)
    {
        if (in.empty()) return {};
        int enc_len = 4 * ((in.size() + 2) / 3);
        std::string out(enc_len, '\0');
        int written = EVP_EncodeBlock(reinterpret_cast<unsigned char*>(out.data()),
                                      in.data(), static_cast<int>(in.size()));
        out.resize(written);
        return out;
    }

    bool Base64Decode(std::string const& in, std::vector<uint8_t>& out)
    {
        if (in.empty()) { out.clear(); return true; }
        out.assign(in.size(), 0);
        int decoded = EVP_DecodeBlock(out.data(),
                                      reinterpret_cast<const unsigned char*>(in.data()),
                                      static_cast<int>(in.size()));
        if (decoded < 0) return false;
        // Adjust for padding
        int pad = 0;
        if (in.size() >= 2 && in[in.size()-1] == '=') pad++;
        if (in.size() >= 2 && in[in.size()-2] == '=') pad++;
        out.resize(decoded - pad);
        return true;
    }

    SymmetricKey DeriveKey(std::string const& passphrase,
                           std::vector<uint8_t> const& salt,
                           uint32_t timeCost, uint32_t memoryKB,
                           uint32_t parallelism)
    {
        SymmetricKey key(32, 0);
        int rc = argon2id_hash_raw(
            timeCost, memoryKB, parallelism,
            passphrase.data(), passphrase.size(),
            salt.data(), salt.size(),
            key.data(), key.size());
        if (rc != ARGON2_OK)
        {
            LOG_ERROR("module", "[WCPX] argon2id_hash_raw failed: {}", argon2_error_message(rc));
            return {};
        }
        return key;
    }

    bool AeadEncrypt(SymmetricKey const& key,
                     std::vector<uint8_t> const& iv,
                     std::vector<uint8_t> const& aad,
                     std::vector<uint8_t> const& plaintext,
                     std::vector<uint8_t>& ctOut,
                     std::vector<uint8_t>& tagOut)
    {
        if (key.size() != 32 || iv.size() != 12) return false;
        EVP_CIPHER_CTX* ctx = EVP_CIPHER_CTX_new();
        if (!ctx) return false;
        bool ok = false;
        do
        {
            if (EVP_EncryptInit_ex(ctx, EVP_aes_256_gcm(), nullptr, nullptr, nullptr) != 1) break;
            if (EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_IVLEN, 12, nullptr) != 1) break;
            if (EVP_EncryptInit_ex(ctx, nullptr, nullptr, key.data(), iv.data()) != 1) break;

            int len = 0;
            if (!aad.empty())
            {
                if (EVP_EncryptUpdate(ctx, nullptr, &len, aad.data(), static_cast<int>(aad.size())) != 1)
                    break;
            }

            ctOut.assign(plaintext.size(), 0);
            if (EVP_EncryptUpdate(ctx, ctOut.data(), &len,
                                  plaintext.data(), static_cast<int>(plaintext.size())) != 1)
                break;
            int total = len;
            if (EVP_EncryptFinal_ex(ctx, ctOut.data() + len, &len) != 1) break;
            total += len;
            ctOut.resize(total);

            tagOut.assign(16, 0);
            if (EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_GET_TAG, 16, tagOut.data()) != 1) break;
            ok = true;
        } while (false);
        EVP_CIPHER_CTX_free(ctx);
        return ok;
    }

    bool AeadDecrypt(SymmetricKey const& key,
                     std::vector<uint8_t> const& iv,
                     std::vector<uint8_t> const& aad,
                     std::vector<uint8_t> const& ct,
                     std::vector<uint8_t> const& tag,
                     std::vector<uint8_t>& ptOut)
    {
        if (key.size() != 32 || iv.size() != 12 || tag.size() != 16) return false;
        EVP_CIPHER_CTX* ctx = EVP_CIPHER_CTX_new();
        if (!ctx) return false;
        bool ok = false;
        do
        {
            if (EVP_DecryptInit_ex(ctx, EVP_aes_256_gcm(), nullptr, nullptr, nullptr) != 1) break;
            if (EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_IVLEN, 12, nullptr) != 1) break;
            if (EVP_DecryptInit_ex(ctx, nullptr, nullptr, key.data(), iv.data()) != 1) break;

            int len = 0;
            if (!aad.empty())
            {
                if (EVP_DecryptUpdate(ctx, nullptr, &len, aad.data(), static_cast<int>(aad.size())) != 1)
                    break;
            }

            ptOut.assign(ct.size(), 0);
            if (EVP_DecryptUpdate(ctx, ptOut.data(), &len,
                                  ct.data(), static_cast<int>(ct.size())) != 1)
                break;
            int total = len;

            // Set expected tag before final.
            if (EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_TAG, 16,
                                    const_cast<uint8_t*>(tag.data())) != 1) break;

            if (EVP_DecryptFinal_ex(ctx, ptOut.data() + len, &len) != 1) break;
            total += len;
            ptOut.resize(total);
            ok = true;
        } while (false);
        EVP_CIPHER_CTX_free(ctx);
        return ok;
    }

    bool Sign(std::string const& privateKeyPemPath,
              std::vector<uint8_t> const& message,
              std::vector<uint8_t>& sigOut)
    {
        FILE* f = fopen(privateKeyPemPath.c_str(), "rb");
        if (!f)
        {
            LOG_ERROR("module", "[WCPX] cannot open private key at {}", privateKeyPemPath);
            return false;
        }
        EVP_PKEY* pkey = PEM_read_PrivateKey(f, nullptr, nullptr, nullptr);
        fclose(f);
        if (!pkey) return false;

        EVP_MD_CTX* ctx = EVP_MD_CTX_new();
        bool ok = false;
        do
        {
            if (!ctx) break;
            if (EVP_DigestSignInit(ctx, nullptr, nullptr, nullptr, pkey) != 1) break;
            size_t siglen = 0;
            if (EVP_DigestSign(ctx, nullptr, &siglen, message.data(), message.size()) != 1) break;
            sigOut.assign(siglen, 0);
            if (EVP_DigestSign(ctx, sigOut.data(), &siglen, message.data(), message.size()) != 1) break;
            sigOut.resize(siglen);
            ok = true;
        } while (false);
        EVP_MD_CTX_free(ctx);
        EVP_PKEY_free(pkey);
        return ok;
    }

    bool Verify(std::vector<uint8_t> const& pubKey,
                std::vector<uint8_t> const& message,
                std::vector<uint8_t> const& signature)
    {
        if (pubKey.size() != 32) return false;
        EVP_PKEY* pkey = EVP_PKEY_new_raw_public_key(EVP_PKEY_ED25519, nullptr,
                                                     pubKey.data(), pubKey.size());
        if (!pkey) return false;
        EVP_MD_CTX* ctx = EVP_MD_CTX_new();
        bool ok = false;
        do
        {
            if (!ctx) break;
            if (EVP_DigestVerifyInit(ctx, nullptr, nullptr, nullptr, pkey) != 1) break;
            int rc = EVP_DigestVerify(ctx, signature.data(), signature.size(),
                                      message.data(), message.size());
            ok = (rc == 1);
        } while (false);
        EVP_MD_CTX_free(ctx);
        EVP_PKEY_free(pkey);
        return ok;
    }
}
