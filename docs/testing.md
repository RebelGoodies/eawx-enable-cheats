# Testing

Tests run with Lua 5.1, [Busted](https://olivinelabs.com/busted/), and
[eaw-abstraction-layer](https://github.com/SvenMarcus/eaw-abstraction-layer).

### Setup and commands

This assumes a Unix or WSL shell with `lua-5.1` and `luarocks` available in the path.

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

> Note: luaJIT does not supply the implicit local `arg` table, so some contract tests may fail.

## Structure

Tests are grouped by behavior and boundary:
```
test/
  config.lua
  unit/
  contracts/
  support/
```

The suite runs the real picker and plugin entry point inside `eaw.run()` with configured EaW object-type mocks.
It checks constructor arguments for supported mods, deferred and idempotent cheat activation, and unsupported-mod handling.

### Installed Workshop contracts

By default, the upstream contract suite is skipped when `WORKSHOP_EAW` is unset or invalid.
To run against installed Steam Workshop files, set the variable to the `workshop/content/32470` directory.

The suite expects all three installations, with `Data/` beneath each directory:

| Workshop directory | Mod | Picker marker |
|--------------------|-----|---------------|
| `1125571106` | Thrawn's Revenge | `icw` |
| `1976399102` | Fall of the Republic | `fotr` |
| `3417277973` | Revan's Revenge | `rev` |

- Each `deepcore/std/class.lua` and `OptionsHandler.lua` is loaded
- Assertions check required constructor bindings and calls from `enable_cheats()`

> These checks verify Lua contracts and mocked calls, not in-game cheat unlocking or UI behavior.

### Runtime compatibility

The game runs Lua 5.0.3, while these host tests run Lua 5.1.

- The implicit local `arg` table is used by upstream class constructors, so the fixture loads their original files directly.
- Lua 5.1's `unpack(arg)` does not honor `arg.n`, so sparse arguments or trailing nil values can be lost during upstream class forwarding.
- The contracts check the actual non-nil constructor values used by the picker, including FotR's campaign name and Revan's human player.
