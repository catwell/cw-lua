LMODNAME=chacha
LUA=lua

CFLAGS = -fPIC -Wall -g
LDFLAGS = -shared 


.PHONY: all clean

all: chacha.so

clean:
	rm -f *.o *.so

chacha.so: chacha.o lchacha.o
	$(CC) $(LDFLAGS) -o $@ $^

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $^

test:
	$(LUA) $(LMODNAME).test.lua
