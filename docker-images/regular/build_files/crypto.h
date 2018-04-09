#ifndef _CRYPTO_H_
#define _CRYPTO_H_

#include <string>
#include <crypto++/rsa.h>

namespace Crypto {

typedef CryptoPP::RSA::PublicKey PubKey;
typedef CryptoPP::RSA::PrivateKey PrvKey;

std::string encrypt_aes( const std::string &plain );
void encrypt_aes_inline( std::string & );
void decrypt_aes_inline( std::string & );
std::string decrypt_aes( const std::string &cipher );
std::string encrypt_rsa( const PubKey &pubkey, const std::string &plain );
std::string decrypt_rsa( const PrvKey &prvkey, const std::string &cipher );
std::string printable( const std::string &s );
void decodeBase64PublicKey(const std::string& filename, PubKey& key);
void decodeBase64PrivateKey(const std::string& filename, PrvKey& key);

}
#endif
