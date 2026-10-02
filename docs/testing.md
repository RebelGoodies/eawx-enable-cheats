# Testing

Tests run with Lua 5.1, [Busted](https://olivinelabs.com/busted/), and
[eaw-abstraction-layer](https://github.com/SvenMarcus/eaw-abstraction-layer).

### Setup and commands

Install the required dependencies:
```sh
luarocks --lua-version=5.1 install --local busted
luarocks --lua-version=5.1 install --local eaw-abstraction-layer
```

Check the existing Lua 5.1 environment before running tests:
```sh
lua-5.1 -v
busted --version
luarocks --lua-version=5.1 config
luarocks --lua-version=5.1 path
lua-5.1 -e 'require("busted"); require("eaw-abstraction-layer")'
```

Expose LuaRocks paths for the shell session if needed:
```sh
eval "$(luarocks --lua-version=5.1 path)"
```

### Running tests

Run the full suite from the repository root:
```sh
busted
```

Run only the unit tests with:
```sh
busted test/unit
```

The `.busted` configuration selects `lua-5.1` by default, so that executable must be available.
Pass `--lua=...` to `busted` to override it, such as `--lua=luajit`

## Structure

Tests are grouped by behavior and boundary:
```
test/
  config.lua
  unit/
    options_handler/
    support/
  contracts/
  support/
```

The suite runs the real picker and plugin entry point inside `eaw.run()` with configured EaW object-type mocks.
It checks constructor arguments for supported mods, deferred and idempotent cheat activation, and unsupported-mod handling.
Missing base-mod modules are replaced by isolated test doubles.
