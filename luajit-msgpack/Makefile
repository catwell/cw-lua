PREFIX=/usr/local
CLIBNAME=luajitmsgpack
LMODNAME=luajit-msgpack

UNAME=$(shell uname)
_Linux_cflags= -shared -fPIC
_Darwin_cflags= -undefined dynamic_lookup -dynamiclib
_Linux_libext=so
_Darwin_libext=dylib
_Linux_ldconfig=ldconfig -n
_Darwin_ldconfig=true

CC=gcc
LDCONFIG=$(_$(UNAME)_ldconfig)
LUAJIT=luajit
CFLAGS= -std=c99 -Wall -Werror -lmsgpack $(_$(UNAME)_cflags)
CLIBEXT=$(_$(UNAME)_libext)
CLIBFILE=lib$(CLIBNAME).$(CLIBEXT)
LMODFILE=$(LMODNAME).lua

ABIVER=5.1
INSTALL_LIB=$(PREFIX)/lib
INSTALL_SHARE=$(PREFIX)/share
INSTALL_LMOD=$(INSTALL_SHARE)/lua/$(ABIVER)

BENCH_NLOOP=50000

$(CLIBFILE): $(CLIBNAME).c
	$(CC) $(CFLAGS) -o $@ $<

all: $(CLIBFILE)

clean:
	rm -f $(CLIBFILE)

test:
	@echo "NOTE: tests only work if you have installed luajit-msgpack"
	$(LUAJIT) tests/test.lua

bench:
	$(LUAJIT) tests/bench.lua $(BENCH_NLOOP)

install:
	install -m0644 $(CLIBFILE) $(INSTALL_LIB)/$(CLIBFILE)
	$(LDCONFIG) $(INSTALL_LIB)
	install -m0644 $(LMODFILE) $(INSTALL_LMOD)/$(LMODFILE)

uninstall:
	rm -f $(INSTALL_LIB)/$(CLIBFILE)
	rm -f $(INSTALL_LMOD)/$(LMODFILE)
