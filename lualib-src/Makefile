include ../skynet/platform.mk

CC ?= gcc

SHARED := -fPIC --shared

LUA_CLIB_PATH ?= ../luaclib
SKYNET_BUILD_PATH ?= ../skynet

CFLAGS = -g -O2 -Wall -I$(LUA_INC)

LUA_STATICLIB := ../skynet/3rd/lua/liblua.a
LUA_LIB ?= $(LUA_STATICLIB)
LUA_INC ?= ../skynet/3rd/lua


LUA_CLIB = cjson lfs protobuf

all	: $(LUA_CLIB_PATH)/cjson.so $(LUA_CLIB_PATH)/lfs.so $(LUA_CLIB_PATH)/protobuf.so

$(LUA_CLIB_PATH)/cjson.so : lua-cjson/fpconv.c lua-cjson/strbuf.c lua-cjson/lua_cjson.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) -Ilua-cjson $^ -o $@

$(LUA_CLIB_PATH)/lfs.so : luafilesystem/src/lfs.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) -Iluafilesystem/src $^ -o $@

$(LUA_CLIB_PATH)/protobuf.so : pbc/binding/lua53/pbc-lua53.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) -Ipbc -Lpbc/build $^ -o $@ -lpbc

clean :
	rm -f $(LUA_CLIB_PATH)/*.so
	rm -rf pbc/build
