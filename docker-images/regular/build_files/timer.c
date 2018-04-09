////////////////////////////////////////////////////////////////
// From HighResTimer.c by Cody Duncan
// adapted for Lua5.3 by Aurelien Havet
//
// compile with:  gcc -o Timer.so -shared HighResTimer.c -llua5.1
// compiled in cygwin after installing lua (cant remember if I
//   installed via setup or if I downloaded and compiled lua,
//   probably the former)
////////////////////////////////////////////////////////////////

#include <time.h>
#include <sys/time.h>

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

struct timeval start, cue;

int time_ms(struct timeval time) {
  return (time.tv_sec * 1000000 + time.tv_usec);
}

static int now(lua_State *L)
{
    struct timeval now;
    gettimeofday(&now, NULL);
    lua_pushnumber(L, time_ms(now));
    return 1;
}

static int since_start(lua_State *L)
{
    struct timeval now;
    gettimeofday(&now, NULL);
    lua_pushnumber(L, time_ms(now) - time_ms(start));
    return 1;
}

static int start_time(lua_State *L)
{
    lua_pushnumber(L, time_ms(start));
    return 1;
}

static int set_cue(lua_State *L)
{
    gettimeofday(&cue, NULL);
    lua_pushnumber(L, time_ms(cue));
    return 1;
}

static int get_cue(lua_State *L)
{
    lua_pushnumber(L, time_ms(cue));
    return 1;
}

static int since_cue(lua_State *L)
{
    struct timeval now;
    gettimeofday(&now, NULL);
    lua_pushnumber(L, time_ms(now) - time_ms(cue));
    return 1;
}


int luaopen_timer (lua_State *L) {
    gettimeofday(&start, NULL);

    static const luaL_Reg timerlib [] =
    {
        {"now", now},
        {"since_start", since_start},
        {"start_time", start_time},
        {"set_cue", set_cue},
        {"get_cue", get_cue},
        {"since_cue", since_cue},
        {NULL, NULL}  /* sentinel */
    };

    luaL_newlib(L, timerlib);

    return 1;
}
