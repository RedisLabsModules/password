#set environment variable RM_INCLUDE_DIR to the location of redismodule.h
ifndef RM_INCLUDE_DIR
	RM_INCLUDE_DIR=../
endif

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
BLOWFISH_DIR = crypt_blowfish-1.3
BLOWFISH_OBJS = \
	$(BLOWFISH_DIR)/crypt_blowfish.o \
	$(BLOWFISH_DIR)/crypt_gensalt.o \
	$(BLOWFISH_DIR)/wrapper.o \
	$(BLOWFISH_DIR)/x86.o

CFLAGS = -I$(RM_INCLUDE_DIR) -I$(BLOWFISH_DIR) -Wall -g -fPIC -Og -std=gnu99  
CC=gcc
.SUFFIXES: .c .so .xo .o

all: password.so

password.so: password.o $(BLOWFISH_OBJS)
	$(LD) -o $@ password.o $(BLOWFISH_OBJS) $(SHOBJ_LDFLAGS) $(LIBS) -lc 

clean:
	rm -rf *.xo *.so *.o $(BLOWFISH_OBJS)

test: all
	./test.sh
