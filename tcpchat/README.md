# tcpchat

## Presentation

This is sample code, not a real application you should use.

What it does:

- If you connect on port 3333, you join a simple, IRC-like chatroom.
- If you connect on port 3334, you enter a Lua interpreter
  *inside the chat process*.

This means you can do things like this:

    for _,v in ipairs(chat_sessions()) do
        v:message("Hello from a ghost.")
    end

## Copyright

Copyright (c) 2015 Pierre Chapuis
