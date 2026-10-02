---@class UpstreamOptionsHandlerMod
---@field name string
---@field id string
---@field marker string

---@class UpstreamOptionsHandlerPlayer
---@field Get_Faction_Name fun(): string
---@field Unlock_Tech fun(object_type: string)

---@class UpstreamOptionsHandlerSubscription
---@field topic string
---@field callback function
---@field owner table

---@class UpstreamOptionsHandlerListener
---@field callback function
---@field owner table

---@class UpstreamOptionsHandlerState
---@field unlocks string[]
---@field messages string[]
---@field subscriptions UpstreamOptionsHandlerSubscription[]
---@field listeners UpstreamOptionsHandlerListener[]
---@field values table<string, any>
---@field player UpstreamOptionsHandlerPlayer
---@field player_lookups? integer
---@field gc {HumanPlayer: UpstreamOptionsHandlerPlayer, Events: table<string, table>}
---@field Picker fun(gc: table, id: string, gc_name: string): OptionsHandlerPicker
---@field Handler table
