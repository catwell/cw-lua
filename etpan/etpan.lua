local ll = require "etpan_ll"

local enum = function(base, t)
    local r = {}
    for i = base, #t + base - 1 do
        local v = t[i + 1 - base]
        r[v] = i
        r[i] = v
    end
    return r
end

local IMAP_ERROR = enum(0, {
    "NO_ERROR",
    "NO_ERROR_AUTHENTICATED",
    "NO_ERROR_NON_AUTHENTICATED",
    "BAD_STATE",
    "STREAM",
    "PARSE",
    "CONNECTION_REFUSED",
    "MEMORY",
    "FATAL",
    "PROTOCOL",
    "DONT_ACCEPT_CONNECTION",
    "APPEND",
    "NOOP",
    "LOGOUT",
    "CAPABILITY",
    "CHECK",
    "CLOSE",
    "EXPUNGE",
    "COPY",
    "UID_COPY",
    "MOVE",
    "UID_MOVE",
    "CREATE",
    "DELETE",
    "EXAMINE",
    "FETCH",
    "UID_FETCH",
    "LIST",
    "LOGIN",
    "LSUB",
    "RENAME",
    "SEARCH",
    "UID_SEARCH",
    "SELECT",
    "STATUS",
    "STORE",
    "UID_STORE",
    "SUBSCRIBE",
    "UNSUBSCRIBE",
    "STARTTLS",
    "INVAL",
    "EXTENSION",
    "SASL",
    "SSL",
    "NEEDS_MORE_DATA",
    "CUSTOM_COMMAND"
})

local imap_is_error = function(c)
    return (
        c ~= IMAP_ERROR.NO_ERROR and
        c ~= IMAP_ERROR.NO_ERROR_AUTHENTICATED and
        c ~= IMAP_ERROR.NO_ERROR_NON_AUTHENTICATED
    )
end

local imap = {
    ERROR = IMAP_ERROR,
    is_error = imap_is_error,
}

return {
    ll = ll,
    imap = imap,
}
