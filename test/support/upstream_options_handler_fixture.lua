local assert = require("luassert")

local picker_module = "eawx-plugins/options-handler/OptionsHandlerPicker"
local class_module = "deepcore/std/class"
local handler_module = "eawx-plugins/options-handler/OptionsHandler"
local dependencies = {
    class_module, handler_module, picker_module,
    "eawx-util/StoryUtil", "eawx-util/ChangeOwnerUtilities", "deepcore/crossplot/crossplot"
}

---@generic K, V
---@param source table<K, V>
---@return table<K, V>
local function snapshot(source)
    local copy = {}
    for key, value in pairs(source) do copy[key] = value end
    return copy
end

---@generic K, V
---@param target table<K, V>
---@param saved table<K, V>
local function restore(target, saved)
    for key in pairs(target) do
        if saved[key] == nil then target[key] = nil end
    end
    for key, value in pairs(saved) do target[key] = value end
end

---@param path string
---@return function
local function file_loader(path)
    local loader, err = loadfile(path)
    if not loader then
        error("WORKSHOP_EAW: cannot load upstream module " .. path .. ": " .. tostring(err), 0)
    end
    return loader
end

---@param root string
---@param mod UpstreamOptionsHandlerMod
---@param test fun(state: UpstreamOptionsHandlerState)
local function run(root, mod, test)
    local loaded, preloads, globals = snapshot(package.loaded), snapshot(package.preload), snapshot(_G)
    local original_path = package.path
    local ok, err = pcall(function()
        local library = root .. "/" .. mod.id .. "/Data/Scripts/Library/"
        for _, name in ipairs(dependencies) do
            package.loaded[name] = nil
            package.preload[name] = nil
        end
        -- Exact files prevent a missing installation from falling back to another mod.
        package.preload[class_module] = file_loader(library .. class_module .. ".lua")
        package.preload[handler_module] = file_loader(library .. handler_module .. ".lua")
        package.preload[picker_module] = file_loader("mod/Data/Scripts/Library/" .. picker_module .. ".lua")
        local state = {unlocks = {}, messages = {}, subscriptions = {}, listeners = {}, values = {}}
        ---@cast state UpstreamOptionsHandlerState
        local player = {
            Get_Faction_Name = function() return "TEST_FACTION" end,
            Unlock_Tech = function(object_type) state.unlocks[#state.unlocks + 1] = object_type end
        }
        local event = {attach_listener = function(_, callback, owner)
            state.listeners[#state.listeners + 1] = {callback = callback, owner = owner}
        end}
        state.player = player
        state.gc = {HumanPlayer = player, Events = {GalacticProductionFinished = event}}
        Find_Player = function(name)
            assert.equals("local", name)
            state.player_lookups = (state.player_lookups or 0) + 1
            return player
        end
        Find_Object_Type = function(name)
            if name == mod.marker or name:match("^Cheat_") then return name end
            return nil
        end
        GlobalValue = {Set = function(key, value) state.values[key] = value end}
        ModContentLoader = {get = function(name)
            assert.equals("GameConstants", name)
            return {}
        end}
        package.preload["deepcore/crossplot/crossplot"] = function()
            crossplot = {subscribe = function(_, topic, callback, owner)
                state.subscriptions[#state.subscriptions + 1] = {topic = topic, callback = callback, owner = owner}
            end}
            return crossplot
        end
        package.preload["eawx-util/StoryUtil"] = function()
            StoryUtil = {ShowScreenText = function(text) state.messages[#state.messages + 1] = text end}
            return StoryUtil
        end
        -- Unused by new()/enable_cheats(); loading the real utility would run game setup.
        package.preload["eawx-util/ChangeOwnerUtilities"] = function() return {} end
        state.Picker = require(picker_module)
        state.Handler = OptionsHandler
        test(state)
    end)
    restore(package.loaded, loaded)
    restore(package.preload, preloads)
    package.path = original_path
    restore(_G, globals)
    if not ok then error(err, 0) end
end

return {run = run}
