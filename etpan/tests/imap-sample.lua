local lfs = require "lfs"
local etpan = require "etpan"
local fmt = string.format

local check_error = function(c)
    if etpan.imap.is_error(c) then
        error(etpan.imap.ERROR[c] or tostring(c), 2)
    end
end

local get_msg_content = function(fetch_result)
    local cur = etpan.ll.clist.begin(fetch_result)
    while cur do
        local msg_att = etpan.ll.clist.content(cur)
        local msg_content = etpan.ll.msg_att.get_msg_content(msg_att)
        if msg_content then return msg_content end
        cur = etpan.ll.clist.next(cur)
    end
end

local fetch_msg = function(imap, uid)

    local filename = fmt("download/%d.eml", uid)
    if lfs.attributes(filename) then
        print(fmt("%d is already fetched", uid))
        return
    end

    local set = etpan.ll.imap.set.new_single(uid)
    local fetch_type = etpan.ll.imap.fetch_type.new_fetch_att_list_empty()
    local section = etpan.ll.section.new()
    local fetch_att = etpan.ll.imap.fetch_att.new_body_peek_section(section)
    etpan.ll.imap.fetch_type.new_fetch_att_list_add(fetch_type, fetch_att)

    local r, fetch_result = etpan.ll.imap.uid_fetch(imap, set, fetch_type)
    check_error(r)
    print(fmt("fetch %d", uid))

    local msg_content = get_msg_content(fetch_result)
    if not msg_content then
        io.stderr:write("no content\n")
        etpan.ll.imap.fetch_list_free(fetch_result)
        return
    end

    local f = io.open(filename, "w")
    if not f then
        io.stderr:write("could not write\n")
        etpan.ll.imap.fetch_list_free(fetch_result)
        return
    end
    f:write(msg_content)
    f:close()

    print(fmt("%d has been fetched", uid))
    etpan.ll.imap.fetch_list_free(fetch_result)
end

local fetch_messages = function(imap)
    local set = etpan.ll.imap.set.new_interval(1, 0)
    local fetch_type = etpan.ll.imap.fetch_type.new_fetch_att_list_empty()
    local fetch_att = etpan.ll.imap.fetch_att.new_uid()
    etpan.ll.imap.fetch_type.new_fetch_att_list_add(fetch_type, fetch_att)
    local r, fetch_result = etpan.ll.imap.fetch(imap, set, fetch_type)
    check_error(r)
    local cur = etpan.ll.clist.begin(fetch_result)
    while cur do
        local msg_att = etpan.ll.clist.content(cur)
        local uid = etpan.ll.msg_att.get_uid(msg_att)
        if uid ~= 0 then
            fetch_msg(imap, uid)
        end
        cur = etpan.ll.clist.next(cur)
    end
    etpan.ll.imap.fetch_list_free(fetch_result)
end

local main = function(arg)
    assert(arg[1] and arg[2], fmt("USAGE: %s userid password", arg[0]))

    lfs.mkdir("download")

    local imap = etpan.ll.imap.new()

    check_error(etpan.ll.imap.ssl_connect(imap, "imap.gmail.com", 993))
    check_error(etpan.ll.imap.login(imap, arg[1], arg[2]))
    check_error(etpan.ll.imap.select(imap, "INBOX"))

    fetch_messages(imap)

    etpan.ll.imap.logout(imap)
    etpan.ll.imap.free(imap)
end

main(arg)
