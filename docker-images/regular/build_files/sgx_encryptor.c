////////////////////////////////////////////////////////////////
// From HighResTimer.c by Cody Duncan
// adapted for Lua5.3 by Aurelien Havet
//
// compile with:  gcc -o Timer.so -shared HighResTimer.c -llua5.1
// compiled in cygwin after installing lua (cant remember if I
//   installed via setup or if I downloaded and compiled lua,
//   probably the former)
////////////////////////////////////////////////////////////////


#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

#include "crypto.h"

//------------------------------------------------------------------------------
static int l_sgx_encrypt( lua_State *L ) {
    size_t sz;
    const char *plain = luaL_checklstring( L, 1, &sz );
    std::string cipher(plain,sz);
    Crypto::encrypt_aes_inline( cipher );
    lua_pushlstring(L,cipher.c_str(),cipher.size());
    return 1;
}

//------------------------------------------------------------------------------
static int l_sgx_decrypt( lua_State *L ) {
    size_t sz;
    const char *cipher = luaL_checklstring( L, 1, &sz );
    std::string plain( cipher, sz );
    Crypto::decrypt_aes_inline( plain );
    lua_pushlstring(L,plain.c_str(),plain.size());
    return 1;
}

//------------------------------------------------------------------------------


extern "C" {
  int luaopen_sgx_encryptor (lua_State *L) {

    static const luaL_Reg sgx_encrypt_lib [] =
    {
        {"encrypt", l_sgx_encrypt},
        {"decrypt", l_sgx_decrypt},
        {NULL, NULL}  /* sentinel */
    };

    luaL_newlib(L, sgx_encrypt_lib);

    return 1;
  }
}
