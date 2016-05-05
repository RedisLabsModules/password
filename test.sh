#!/usr/bin/shunit2

testRedisAlive() {
    res=`redis-cli ping`
    assertEquals "PONG" "$res"
}

testLoadModule() {
    curdir=`pwd`
    res=`redis-cli module load ${curdir}/password.so`
    assertEquals "OK" "$res"
}

testPasswordSetAndCheck() {
    res=`redis-cli password.set mypassword 12345`
    assertEquals "OK" "$res"

    res=`redis-cli get mypassword|head -c4`
    assertEquals '$2y$' "$res"

    res=`redis-cli password.check mypassword incorrect`
    assertEquals 0 "$res"

    res=`redis-cli password.check mypassword 12345`
    assertEquals 1 "$res"
}

testPasswordHSetAndHCheck() {
    redis-cli del myhash >/dev/null
    res=`redis-cli password.hset myhash mypassword 12345`
    assertEquals 1 "$res"

    res=`redis-cli hget myhash mypassword|head -c4`
    assertEquals '$2y$' "$res"

    res=`redis-cli password.hcheck myhash mypassword incorrect`
    assertEquals 0 "$res"

    res=`redis-cli password.hcheck myhash mypassword 12345`
    assertEquals 1 "$res"
}

testWrongTypeOnCheck() {
    redis-cli del mylist >/dev/null
    redis-cli sadd mylist 1 >/dev/null
    res=`redis-cli password.check mylist pass`
    assertEquals "WRONGTYPE Operation against a key holding the wrong kind of value" "$res"
}

testWrongTypeOnHCheck() {
    redis-cli del mylist >/dev/null
    redis-cli sadd mylist 1 >/dev/null
    res=`redis-cli password.hcheck mylist mypass pass`
    assertEquals "WRONGTYPE Operation against a key holding the wrong kind of value" "$res"
}

testEmptyValue() {
    redis-cli del mypassword >/dev/null
    res=`redis-cli password.check mypassword ""`
    assertEquals "0" "$res"
}

