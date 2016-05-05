#set environment variable RM_INCLUDE_DIR to the location of redismodule.h
ifndef RM_INCLUDE_DIR
	RM_INCLUDE_DIR=../
endif

DEFS = -D_GNU_SOURCE

# find the OS
uname_S := $(shell sh -c 'uname -s 2>/dev/null || echo not')

# Compile flags for linux / osx
ifeq ($(uname_S),Linux)
	SHOBJ_CFLAGS ?=  -fno-common -g -ggdb
	SHOBJ_LDFLAGS ?= -shared -Bsymbolic
else
	SHOBJ_CFLAGS ?= -dynamic -fno-common -g -ggdb
	SHOBJ_LDFLAGS ?= -bundle -undefined dynamic_lookup
endif
CFLAGS = -I$(RM_INCLUDE_DIR) $(DEFS) -Wall -g -fPIC -Og -std=gnu99  
LIBS = -lcrypt
CC=gcc
.SUFFIXES: .c .so .xo .o

all: password.so 

password.so: password.o
	$(LD) -o $@ password.o $(SHOBJ_LDFLAGS) $(LIBS) -lc 

clean:
	rm -rf *.xo *.so *.o

test: all
	./test.sh
