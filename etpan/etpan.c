#include <stdlib.h>
#include <stdbool.h>

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

#include <libetpan/libetpan.h>

static int ll_mailimap_new(lua_State *L)
{
    struct mailimap *p = mailimap_new(0, NULL);
    lua_pushlightuserdata(L, p);
    return 1;
}

static int ll_mailimap_free(lua_State *L)
{
    luaL_checktype(L, 1, LUA_TLIGHTUSERDATA);
    struct mailimap *p = lua_touserdata(L, 1);
    mailimap_free(p);
    return 0;
}

static int ll_mailimap_ssl_connect(lua_State *L)
{
    luaL_checktype(L, 1, LUA_TLIGHTUSERDATA);
    luaL_checktype(L, 2, LUA_TSTRING);
    luaL_checktype(L, 3, LUA_TNUMBER);
    struct mailimap *p = lua_touserdata(L, 1);
    const char *server = lua_tostring(L, 2);
    uint16_t port = lua_tointeger(L, 3);
    int r = mailimap_ssl_connect(p, server, port);
    lua_pushinteger(L, r);
    return 1;
}

static int ll_mailimap_login(lua_State *L)
{
    luaL_checktype(L, 1, LUA_TLIGHTUSERDATA);
    luaL_checktype(L, 2, LUA_TSTRING);
    luaL_checktype(L, 3, LUA_TSTRING);
    struct mailimap *p = lua_touserdata(L, 1);
    const char *userid = lua_tostring(L, 2);
    const char *password = lua_tostring(L, 3);
    int r = mailimap_login(p, userid, password);
    lua_pushinteger(L, r);
    return 1;
}

static int ll_mailimap_logout(lua_State *L)
{
    luaL_checktype(L, 1, LUA_TLIGHTUSERDATA);
    struct mailimap *p = lua_touserdata(L, 1);
    mailimap_logout(p);
    return 0;
}

static int ll_mailimap_select(lua_State *L)
{
    luaL_checktype(L, 1, LUA_TLIGHTUSERDATA);
    luaL_checktype(L, 2, LUA_TSTRING);
    struct mailimap *p = lua_touserdata(L, 1);
    const char *mailbox = lua_tostring(L, 2);
    int r = mailimap_select(p, mailbox);
    lua_pushinteger(L, r);
    return 1;
}

int luaopen_etpan_ll(lua_State *L)
{
    struct luaL_Reg imap[] = {
        { "new", ll_mailimap_new },
        { "free", ll_mailimap_free },
        { "ssl_connect", ll_mailimap_ssl_connect },
        { "login", ll_mailimap_login },
        { "logout", ll_mailimap_logout },
        { "select", ll_mailimap_select },
        { NULL, NULL }
    };

    lua_newtable(L); /* ll */
    luaL_newlib(L, imap);
    lua_setfield (L, -2, "imap");

    return 1;
}
