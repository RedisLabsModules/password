#include "redismodule.h"

#include <string.h>
#include "ow-crypt.h"

#define SHA512_SALT "$2y$10"

static char *do_crypt(const char *password, char *output, int output_len)
{
    char salt[16];
    char tmp[64];
    char *setting;

    FILE *fp = fopen("/dev/urandom","r");
    if (!fp) return NULL;
    if (fread(salt, sizeof(salt), 1, fp) != 1) {
        fclose(fp);
        return NULL;
    }
    fclose(fp);

    memset(tmp, 0, sizeof(tmp));
    if (!(setting = crypt_gensalt_rn("$2y$", 0, salt, sizeof(salt),
                    tmp, sizeof(tmp))))
        return NULL;

    memset(output, 0, output_len);
    return crypt_rn(password, setting, output, output_len);
}

static int cmd_password_set(RedisModuleCtx *ctx, RedisModuleString **argv, int argc) {
    RedisModuleCallReply *reply;
    size_t len;
    char crypt_buf[64];
    char *hash;

    if (argc != 3) {
        RedisModule_WrongArity(ctx);
        return REDISMODULE_OK;
    }

    hash = do_crypt(RedisModule_StringPtrLen(argv[2], &len), crypt_buf, sizeof(crypt_buf));
    if (!hash) {
        RedisModule_ReplyWithError(ctx, "ERR hash error");
        return REDISMODULE_ERR;
    }
    reply = RedisModule_Call(ctx, "SET", "sc!", argv[1], hash);
    RedisModule_ReplyWithCallReply(ctx, reply);

    return REDISMODULE_OK;
}


static int cmd_password_hset(RedisModuleCtx *ctx, RedisModuleString **argv, int argc) {
    RedisModuleCallReply *reply;
    size_t len;
    char crypt_buf[64];
    char *hash;

    if (argc != 4) {
        RedisModule_WrongArity(ctx);
        return REDISMODULE_OK;
    }

    hash = do_crypt(RedisModule_StringPtrLen(argv[3], &len), crypt_buf, sizeof(crypt_buf));
    if (!hash) {
        RedisModule_ReplyWithError(ctx, "ERR hash error");
        return REDISMODULE_ERR;
    }
    reply = RedisModule_Call(ctx, "HSET", "ssc!", argv[1], argv[2], hash);
    RedisModule_ReplyWithCallReply(ctx, reply);

    return REDISMODULE_OK;
}

static void validate(RedisModuleCtx *ctx, RedisModuleCallReply *reply, RedisModuleString *password)
{
    const char *reply_str;
    size_t reply_len;
    const char *pass;
    size_t pass_len;
    const char *crypt_pass;
    size_t crypt_pass_len;
    char crypt_buf[64];

    if (RedisModule_CallReplyType(reply) == REDISMODULE_REPLY_NULL) {
        RedisModule_ReplyWithLongLong(ctx, 0);
        return;
    }

    if (RedisModule_CallReplyType(reply) != REDISMODULE_REPLY_STRING) {
        RedisModule_ReplyWithError(ctx, "WRONGTYPE Operation against a key holding the wrong kind of value");
        return;
    }

    reply_str = RedisModule_CallReplyStringPtr(reply, &reply_len);
    pass = RedisModule_StringPtrLen(password, &pass_len);

    crypt_pass = crypt_rn(pass, reply_str, crypt_buf, sizeof(crypt_buf));
    if (!crypt_pass) {
        RedisModule_ReplyWithError(ctx, "ERR hash error");
        return;
    }
    crypt_pass_len = strlen(crypt_pass);
    if (crypt_pass_len == reply_len && !memcmp(reply_str, crypt_pass, crypt_pass_len)) {
        RedisModule_ReplyWithLongLong(ctx, 1);
    } else {
        RedisModule_ReplyWithLongLong(ctx, 0);
    }
}

static int cmd_password_check(RedisModuleCtx *ctx, RedisModuleString **argv, int argc) {
    RedisModuleCallReply *reply;

    if (argc != 3) {
        RedisModule_WrongArity(ctx);
        return REDISMODULE_OK;
    }

    reply = RedisModule_Call(ctx, "GET", "s", argv[1]);
    validate(ctx, reply, argv[2]);
    return REDISMODULE_OK;
}

static int cmd_password_hcheck(RedisModuleCtx *ctx, RedisModuleString **argv, int argc) {
    RedisModuleCallReply *reply;

    if (argc != 4) {
        RedisModule_WrongArity(ctx);
        return REDISMODULE_OK;
    }

    reply = RedisModule_Call(ctx, "HGET", "ss", argv[1], argv[2]);
    validate(ctx, reply, argv[3]);
    return REDISMODULE_OK;
}


int RedisModule_OnLoad(RedisModuleCtx *ctx) {
    if (RedisModule_Init(ctx, "password", 1, REDISMODULE_APIVER_1) == REDISMODULE_ERR)
        return REDISMODULE_ERR;

    if (RedisModule_CreateCommand(ctx, "password.set", cmd_password_set,
                "no-monitor fast", 1, 1, 1) == REDISMODULE_ERR)
        return REDISMODULE_ERR;
    if (RedisModule_CreateCommand(ctx, "password.hset", cmd_password_hset,
                "no-monitor fast", 1, 1, 1) == REDISMODULE_ERR)
        return REDISMODULE_ERR;
    if (RedisModule_CreateCommand(ctx, "password.check", cmd_password_check,
                "no-monitor fast", 1, 1, 1) == REDISMODULE_ERR)
        return REDISMODULE_ERR;
    if (RedisModule_CreateCommand(ctx, "password.hcheck", cmd_password_hcheck,
                "no-monitor fast", 1, 1, 1) == REDISMODULE_ERR)
        return REDISMODULE_ERR;

    return REDISMODULE_OK;
}

