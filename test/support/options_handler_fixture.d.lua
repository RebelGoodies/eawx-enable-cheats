---@class OptionsHandlerFixtureOptions
---@field supported? table<string, boolean>
---@field missing_enable_method? boolean

---@class OptionsHandlerFixtureHandler
---@field args table<integer, any>
---@field arg_count integer
---@field enable_calls integer
---@field enable_cheats? fun(self: OptionsHandlerFixtureHandler)

---@class OptionsHandlerFixtureMessage
---@field text string
---@field duration number
---@field color {r: number, g: number, b: number}

---@class OptionsHandlerFixtureContext
---@field galactic_conquest {HumanPlayer: table}
---@field id string
---@field gc_name string

---@class OptionsHandlerFixturePicker
---@field version? integer
---@field enable_cheats fun(self: OptionsHandlerFixturePicker)
---@field get_options_handler fun(self: OptionsHandlerFixturePicker): OptionsHandlerFixtureHandler?

---@class OptionsHandlerFixturePlugin
---@field type string
---@field target table
---@field init fun(self: OptionsHandlerFixturePlugin, context: OptionsHandlerFixtureContext): OptionsHandlerFixtureHandler?

---@class OptionsHandlerFixtureState
---@field handlers OptionsHandlerFixtureHandler[]
---@field messages OptionsHandlerFixtureMessage[]
---@field supported table<string, boolean>
---@field never_target table
---@field Picker fun(gc: table, id: string, gc_name: string): OptionsHandlerFixturePicker
---@field load_plugin fun(): OptionsHandlerFixturePlugin
