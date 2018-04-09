#include <crypto.h>
//#include <wolfssl/wolfcrypt/rsa.h>
#include <fstream>
#include <iostream>
//------------------------------------------------------------------------------
#include <crypto++/osrng.h>
#include <crypto++/cryptlib.h>
using CryptoPP::Exception;
using CryptoPP::BufferedTransformation;
#include <crypto++/filters.h>
using CryptoPP::StringSink;
using CryptoPP::StringSource;
using CryptoPP::StreamTransformationFilter;
#include <cryptopp/files.h>
using CryptoPP::FileSink;
using CryptoPP::FileSource;
#include <crypto++/aes.h>
using CryptoPP::AES;
#include <crypto++/ccm.h>
using CryptoPP::CTR_Mode;
#include <crypto++/base64.h>
using CryptoPP::Base64Decoder;
using CryptoPP::Base64Encoder;
#include <crypto++/queue.h>
using CryptoPP::ByteQueue;
#include <crypto++/hex.h>
//------------------------------------------------------------------------------
namespace Crypto {
//------------------------------------------------------------------------------
void Save(const std::string& filename, const BufferedTransformation& bt) {
    FileSink file(filename.c_str());
    bt.CopyTo(file);
    file.MessageEnd();
}
//------------------------------------------------------------------------------
void SaveBase64(const std::string& filename, const BufferedTransformation& bt) {
    Base64Encoder encoder;
    bt.CopyTo(encoder);
    encoder.MessageEnd();
    Save(filename, encoder);
}
//------------------------------------------------------------------------------
void SaveBase64PrivateKey(const std::string& filename, const PrvKey& key) {
    ByteQueue queue;
    key.Save(queue);
    SaveBase64(filename, queue);
}
//------------------------------------------------------------------------------
void SaveBase64PublicKey(const std::string& filename, const PubKey& key) {
    ByteQueue queue;
    key.Save(queue);
    SaveBase64(filename, queue);
}
//------------------------------------------------------------------------------
void Decode(const std::string& filename, BufferedTransformation& bt) {
    FileSource file(filename.c_str(), true /*pumpAll*/);

    file.TransferTo(bt);
    bt.MessageEnd();
}
//------------------------------------------------------------------------------
void decodeBase64PrivateKey(const std::string& filename, PrvKey& key) {
    Base64Decoder decoder;
    Decode(filename, decoder);
    decoder.MessageEnd();
    key.Load(decoder);
}
//------------------------------------------------------------------------------
void decodeBase64PublicKey(const std::string& filename, PubKey& key) {
    Base64Decoder decoder;
    Decode(filename, decoder);
    decoder.MessageEnd();
    key.Load(decoder);
}
//------------------------------------------------------------------------------
void generateKeysAndSave() {
    CryptoPP::AutoSeededRandomPool rng;

    // Create Keys
    PrvKey privateKey;
    privateKey.GenerateRandomWithKeySize(rng, 3072);

    PubKey publicKey(privateKey);
    SaveBase64PrivateKey( "key.prv", privateKey );
    SaveBase64PublicKey( "key.pub", publicKey );
}
//------------------------------------------------------------------------------
float countchars( const std::string &s ) {
    unsigned count = 0;
    for( std::string::const_iterator it = s.begin(); it != s.end(); ++it )
        if( isgraph(*it) || isspace(*it) ) count++;
    return float(count)/s.size();
}
//------------------------------------------------------------------------------
std::string printable( const std::string &s ) {
    if( countchars(s) < 0.99 ) {
        std::string ret;
        StringSource ssrc( s, true /*pump all*/,
                              new CryptoPP::HexEncoder( new StringSink(ret) ) );
        return ret;
    }
    return s;
}
//------------------------------------------------------------------------------
std::string encrypt_aes( const std::string &plain ) {
    std::string cipher;
    try {
        byte key[16], iv[16];
        memset(key, 0, 16); memset(iv, 0, 16);
        key[0] = 'a'; key[15] = '5';
        iv[0] = 'x'; iv[15] = '?';

        //std::cout << "plain text: " << plain << std::endl;

        CTR_Mode< AES >::Encryption e;
        e.SetKeyWithIV(key, sizeof(key), iv);

        // The StreamTransformationFilter adds padding
        //  as required. ECB and CBC Mode must be padded
        //  to the block size of the cipher.
        StringSource(plain, true,
                   new StreamTransformationFilter(e, new StringSink(cipher) ) );
    } catch(const CryptoPP::Exception& e) {
        std::cerr << e.what() << std::endl;
        exit(1);
    }
    return cipher;
}

//------------------------------------------------------------------------------
void encrypt_aes_inline( std::string &plain ) {
    plain = encrypt_aes(plain);
}

//------------------------------------------------------------------------------
void decrypt_aes_inline( std::string &cipher ) {
    cipher = decrypt_aes(cipher);
}

//------------------------------------------------------------------------------
std::string decrypt_aes( const std::string &cipher ) {
    std::string plain;
    try {
        byte key[16], iv[16];
        memset(key, 0, 16); memset(iv, 0, 16);
        key[0] = 'a'; key[15] = '5';
        iv[0] = 'x'; iv[15] = '?';

        CTR_Mode< AES >::Decryption d;
        d.SetKeyWithIV(key, sizeof(key), iv);

        // The StreamTransformationFilter adds padding
        //  as required. ECB and CBC Mode must be padded
        //  to the block size of the cipher.
        StringSource(cipher, true,
                    new StreamTransformationFilter(d, new StringSink(plain) ) );
    } catch(const CryptoPP::Exception& e) {
        std::cerr << e.what() << std::endl;
        exit(1);
    }
    return plain;
}

//------------------------------------------------------------------------------
std::string encrypt_rsa( const PubKey &pubkey, const std::string &plain ) {
    std::string cipher;
    CryptoPP::AutoSeededRandomPool rng;
    CryptoPP::RSAES_OAEP_SHA_Encryptor e(pubkey);
    StringSource ss1( plain, true,
            new CryptoPP::PK_EncryptorFilter(rng, e, new StringSink(cipher) ) );
    return cipher;
}
//------------------------------------------------------------------------------
std::string decrypt_rsa( const PrvKey &prvkey, const std::string &cipher ) {
    std::string recovered;
    CryptoPP::AutoSeededRandomPool rng;
    CryptoPP::RSAES_OAEP_SHA_Decryptor d(prvkey);

    StringSource ss( cipher, true,
         new CryptoPP::PK_DecryptorFilter(rng, d, new StringSink(recovered) ) );
    return recovered;
}
//------------------------------------------------------------------------------
} // namespace Crypto
