local etpan = require "etpan"
local fmt = string.format

local check_error = function(c)
    if etpan.imap.is_error(c) then
        error(etpan.imap.ERROR[c] or tostring(c), 2)
    end
end

local fetch_messages = function(imap)
    print("TODO")
end

assert(arg[1] and arg[2], fmt("USAGE: %s userid password", arg[0]))

local imap = etpan.ll.imap.new()

check_error(etpan.ll.imap.ssl_connect(imap, "imap.gmail.com", 993))
check_error(etpan.ll.imap.login(imap, arg[1], arg[2]))
check_error(etpan.ll.imap.select(imap, "INBOX"))

fetch_messages(imap)

etpan.ll.imap.logout(imap)
etpan.ll.imap.free(imap)
