Redis Password Module
===

This module provides a simple and secure way to store passwords in Redis
and later verify them.  The passwords are stored as one-way cryptographic
hashes using the bcrypt library, so they cannot be retrieved but only
compared against.

Quick start guide
---

1. Build a Redis server with support for modules.
2. Build the password module: `make`
3. To load the module, Start Redis with the `--loadmodule /path/to/module.so` option, add it as a directive to the configuration file or send a `MODULE LOAD` command.


Commands
---

### `password.set key password`
Works like the standard Redis `SET` command, but stores the hashed password
instead of the clear text password.

### `password.check key password`
Verifies the supplied password against the previously stored password.
**Returns:** `0` if passwords do not match, or `1` if they match.

### `password.hset key field password`
Works like `password.set`, but stores the hashed password in a Hash field
rather than a String field.

### `password.hcheck key field password`
Works like `password.check`, but uses a password stored by `password.hset`
in a Hash field.

Notes
---

* The module uses the C library `crypt()` function with a special salt value
  that causes modern Linux systems to use SHA512.  Very old or non-Linux
  libraries may revert to the less secure version of `crypt()` which is
  cryptographically weak.

* These commands are marked hidden so they do not show up in the `MONITOR`
  feed, to protect sensitive information.

* The command stream that feeds slaves and AOF will only include the hashed
  version of stored passwords.

Contributing
---

Issue reports, pull and feature requests are welcome.

License
---

AGPLv3 - see [LICENSE](LICENSE)
