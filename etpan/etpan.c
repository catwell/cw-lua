#include <stdlib.h>
#include <stdbool.h>

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

#include <libetpan/libetpan.h>

static bool _imap_error(int r)
{
    return (
        r != MAILIMAP_NO_ERROR &&
        r != MAILIMAP_NO_ERROR_AUTHENTICATED &&
        r != MAILIMAP_NO_ERROR_NON_AUTHENTICATED
    );
}

static int ll_mailimap_new(lua_State *L)
{
    struct mailimap *p = mailimap_new(0, NULL);
    if (!p) return 0;
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

static int ll_mailimap_fetch(lua_State *L)
{
    luaL_checktype(L, 1, LUA_TLIGHTUSERDATA);
    luaL_checktype(L, 2, LUA_TLIGHTUSERDATA);
    luaL_checktype(L, 3, LUA_TLIGHTUSERDATA);
    struct mailimap *p1 = lua_touserdata(L, 1);
    struct mailimap_set *p2 = lua_touserdata(L, 2);
    struct mailimap_fetch_type *p3 = lua_touserdata(L, 3);
    clist *fetch_result;
    int r = mailimap_fetch(p1, p2, p3, &fetch_result);
    lua_pushinteger(L, r);
    if (_imap_error(r)) {
        return 1;
    }
    else {
        lua_pushlightuserdata(L, fetch_result);
        return 2;
    }
}

static int ll_mailimap_uid_fetch(lua_State *L)
{
    luaL_checktype(L, 1, LUA_TLIGHTUSERDATA);
    luaL_checktype(L, 2, LUA_TLIGHTUSERDATA);
    luaL_checktype(L, 3, LUA_TLIGHTUSERDATA);
    struct mailimap *p1 = lua_touserdata(L, 1);
    struct mailimap_set *p2 = lua_touserdata(L, 2);
    struct mailimap_fetch_type *p3 = lua_touserdata(L, 3);
    clist *fetch_result;
    int r = mailimap_uid_fetch(p1, p2, p3, &fetch_result);
    lua_pushinteger(L, r);
    if (_imap_error(r)) {
        return 1;
    }
    else {
        lua_pushlightuserdata(L, fetch_result);
        return 2;
    }
}

static int ll_mailimap_fetch_list_free(lua_State *L)
{
    luaL_checktype(L, 1, LUA_TLIGHTUSERDATA);
    clist *p = lua_touserdata(L, 1);
    mailimap_fetch_list_free(p);
    return 0;
}

static int ll_mailimap_set_new_interval(lua_State *L)
{
    luaL_checktype(L, 1, LUA_TNUMBER);
    luaL_checktype(L, 2, LUA_TNUMBER);
    uint32_t first = lua_tointeger(L, 1);
    uint32_t last = lua_tointeger(L, 2);
    struct mailimap_set *p = mailimap_set_new_interval(first, last);
    if (!p) return 0;
    lua_pushlightuserdata(L, p);
    return 1;
}

static int ll_mailimap_set_new_single(lua_State *L)
{
    luaL_checktype(L, 1, LUA_TNUMBER);
    uint32_t indx = lua_tointeger(L, 1);
    struct mailimap_set *p = mailimap_set_new_single(indx);
    if (!p) return 0;
    lua_pushlightuserdata(L, p);
    return 1;
}

static int ll_mailimap_fetch_type_new_fetch_att_list_empty(lua_State *L)
{
    struct mailimap_fetch_type *p =
        mailimap_fetch_type_new_fetch_att_list_empty();
    if (!p) return 0;
    lua_pushlightuserdata(L, p);
    return 1;
}

static int ll_mailimap_fetch_type_new_fetch_att_list_add(lua_State *L)
{
    luaL_checktype(L, 1, LUA_TLIGHTUSERDATA);
    luaL_checktype(L, 2, LUA_TLIGHTUSERDATA);
    struct mailimap_fetch_type *p1 = lua_touserdata(L, 1);
    struct mailimap_fetch_att *p2 = lua_touserdata(L, 2);
    int r = mailimap_fetch_type_new_fetch_att_list_add(p1, p2);
    lua_pushinteger(L, r);
    return 1;
}

static int ll_mailimap_fetch_att_new_uid(lua_State *L)
{
    struct mailimap_fetch_att *p = mailimap_fetch_att_new_uid();
    if (!p) return 0;
    lua_pushlightuserdata(L, p);
    return 1;
}

static int ll_mailimap_fetch_att_new_body_peek_section(lua_State *L)
{
    luaL_checktype(L, 1, LUA_TLIGHTUSERDATA);
    struct mailimap_section *section = lua_touserdata(L, 1);
    struct mailimap_fetch_att *p =
        mailimap_fetch_att_new_body_peek_section(section);
    if (!p) return 0;
    lua_pushlightuserdata(L, p);
    return 1;
}

static int ll_clist_begin(lua_State *L)
{
    luaL_checktype(L, 1, LUA_TLIGHTUSERDATA);
    clist *p = lua_touserdata(L, 1);
    clistiter *rp = clist_begin(p);
    if (!rp) return 0;
    lua_pushlightuserdata(L, rp);
    return 1;
}

static int ll_clist_end(lua_State *L)
{
    luaL_checktype(L, 1, LUA_TLIGHTUSERDATA);
    clist *p = lua_touserdata(L, 1);
    clistiter *rp = clist_end(p);
    if (!rp) return 0;
    lua_pushlightuserdata(L, rp);
    return 1;
}

static int ll_clist_next(lua_State *L)
{
    luaL_checktype(L, 1, LUA_TLIGHTUSERDATA);
    clistiter *p = lua_touserdata(L, 1);
    clistiter *rp = clist_next(p);
    if (!rp) return 0;
    lua_pushlightuserdata(L, rp);
    return 1;
}

static int ll_clist_previous(lua_State *L)
{
    luaL_checktype(L, 1, LUA_TLIGHTUSERDATA);
    clistiter *p = lua_touserdata(L, 1);
    clistiter *rp = clist_previous(p);
    if (!rp) return 0;
    lua_pushlightuserdata(L, rp);
    return 1;
}

static int ll_clist_content(lua_State *L)
{
    luaL_checktype(L, 1, LUA_TLIGHTUSERDATA);
    clistiter *p = lua_touserdata(L, 1);
    void *rp = clist_content(p);
    if (!rp) return 0;
    lua_pushlightuserdata(L, rp);
    return 1;
}

/* from imap-sample.c */
static uint32_t _get_uid(struct mailimap_msg_att * msg_att)
{
    clistiter * cur;

  /* iterate on each result of one given message */
    for(cur = clist_begin(msg_att->att_list) ; cur != NULL ; cur = clist_next(cur)) {
        struct mailimap_msg_att_item * item;

        item = clist_content(cur);
        if (item->att_type != MAILIMAP_MSG_ATT_ITEM_STATIC) {
            continue;
        }

        if (item->att_data.att_static->att_type != MAILIMAP_MSG_ATT_UID) {
            continue;
        }

        return item->att_data.att_static->att_data.att_uid;
    }

    return 0;
}

static int ll_mailimap_msg_att_get_uid(lua_State *L)
{
    luaL_checktype(L, 1, LUA_TLIGHTUSERDATA);
    struct mailimap_msg_att *msg_att = lua_touserdata(L, 1);
    uint32_t r = _get_uid(msg_att);
    lua_pushinteger(L, r);
    return 1;
}

/* from imap-sample.c */
static char * _get_msg_att_msg_content(struct mailimap_msg_att * msg_att, size_t * p_msg_size)
{
    clistiter * cur;

  /* iterate on each result of one given message */
    for(cur = clist_begin(msg_att->att_list) ; cur != NULL ; cur = clist_next(cur)) {
        struct mailimap_msg_att_item * item;

        item = clist_content(cur);
        if (item->att_type != MAILIMAP_MSG_ATT_ITEM_STATIC) {
            continue;
        }

    if (item->att_data.att_static->att_type != MAILIMAP_MSG_ATT_BODY_SECTION) {
            continue;
    }

        * p_msg_size = item->att_data.att_static->att_data.att_body_section->sec_length;
        return item->att_data.att_static->att_data.att_body_section->sec_body_part;
    }

    return NULL;
}

static int ll_mailimap_msg_att_get_msg_content(lua_State *L)
{
    luaL_checktype(L, 1, LUA_TLIGHTUSERDATA);
    struct mailimap_msg_att *msg_att = lua_touserdata(L, 1);
    size_t sz;
    char* p = _get_msg_att_msg_content(msg_att, &sz);
    if (!p) return 0;
    lua_pushlstring(L, p, sz);
    return 1;
}

static int ll_mailimap_section_new(lua_State *L)
{
    struct mailimap_section *p = mailimap_section_new(NULL);
    if (!p) return 0;
    lua_pushlightuserdata(L, p);
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
        { "fetch", ll_mailimap_fetch },
        { "uid_fetch", ll_mailimap_uid_fetch },
        { "fetch_list_free", ll_mailimap_fetch_list_free },
        { NULL, NULL }
    };

    struct luaL_Reg imap_set[] = {
        { "new_interval", ll_mailimap_set_new_interval },
        { "new_single", ll_mailimap_set_new_single },
        { NULL, NULL }
    };

    struct luaL_Reg imap_fetch_type[] = {
        {
            "new_fetch_att_list_empty",
            ll_mailimap_fetch_type_new_fetch_att_list_empty
        },
        {
            "new_fetch_att_list_add",
            ll_mailimap_fetch_type_new_fetch_att_list_add
        },
        { NULL, NULL }
    };

    struct luaL_Reg imap_fetch_att[] = {
        { "new_uid", ll_mailimap_fetch_att_new_uid },
        {
            "new_body_peek_section",
            ll_mailimap_fetch_att_new_body_peek_section
        },
        { NULL, NULL }
    };

    struct luaL_Reg clist[] = {
        { "begin", ll_clist_begin },
        { "end", ll_clist_end },
        { "next", ll_clist_next },
        { "previous", ll_clist_previous },
        { "content", ll_clist_content },
        { NULL, NULL }
    };

    struct luaL_Reg msg_att[] = {
        { "get_uid", ll_mailimap_msg_att_get_uid },
        { "get_msg_content", ll_mailimap_msg_att_get_msg_content },
        { NULL, NULL }
    };

    struct luaL_Reg section[] = {
        { "new", ll_mailimap_section_new },
        { NULL, NULL }
    };

    lua_newtable(L); /* ll */
        luaL_newlib(L, imap);
            luaL_newlib(L, imap_set);
            lua_setfield (L, -2, "set");
            luaL_newlib(L, imap_fetch_att);
            lua_setfield (L, -2, "fetch_att");
            luaL_newlib(L, imap_fetch_type);
            lua_setfield (L, -2, "fetch_type");
        lua_setfield (L, -2, "imap");
        luaL_newlib(L, clist);
        lua_setfield (L, -2, "clist");
        luaL_newlib(L, msg_att);
        lua_setfield (L, -2, "msg_att");
        luaL_newlib(L, section);
        lua_setfield (L, -2, "section");

    return 1;
}
