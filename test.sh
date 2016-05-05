#!/usr/bin/shunit2

testRedisAlive() {
    res=`redis-cli ping`
    assertEquals "PONG" "$res"
}

testLoadModule() {
    res=`redis-cli module load ./password.so`
    assertEquals "OK" "$res"
}

testPasswordSetAndCheck() {
    res=`redis-cli password.set mypassword 12345`
    assertEquals "OK" "$res"

    res=`redis-cli get mypassword`
    assertEquals '$5$$WN3q4DORKzAHdOqVDBVY7CqDDJ6tLOW6pQ6K5I2s/97' "$res"

    res=`redis-cli password.check mypassword incorrect`
    assertEquals 0 "$res"

    res=`redis-cli password.check mypassword 12345`
    assertEquals 1 "$res"
}

testPasswordHSetAndHCheck() {
    redis-cli del myhash >/dev/null
    res=`redis-cli password.hset myhash mypassword 12345`
    assertEquals 1 "$res"

    res=`redis-cli hget myhash mypassword`
    assertEquals '$5$$WN3q4DORKzAHdOqVDBVY7CqDDJ6tLOW6pQ6K5I2s/97' "$res"

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

