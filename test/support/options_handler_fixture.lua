local eaw = require("test.config")

local picker_module = "eawx-plugins/options-handler/OptionsHandlerPicker"
local plugin_module = "eawx-plugins/options-handler/init"
local dependencies = {
    "deepcore/std/class",
    "deepcore/std/plugintargets",
    "deepcore/crossplot/crossplot",
    "eawx-plugins/options-handler/OptionsHandler",
    "eawx-util/StoryUtil"
}
local global_names = {"class", "PluginTargets", "OptionsHandler", "OptionsHandlerPicker", "StoryUtil", "Find_Object_Type"}

local function instantiate(cls, ...)
    local instance = setmetatable({}, cls)
    instance:new(...)
    return instance
end

local function create_class()
    local cls = {}
    cls.__index = cls
    return setmetatable(cls, {__call = instantiate})
end

---@param handler OptionsHandlerFixtureHandler
local function enable_cheats(handler)
    handler.enable_calls = handler.enable_calls + 1
end

---@param options OptionsHandlerFixtureOptions
---@param state OptionsHandlerFixtureState
---@param ... any
---@return OptionsHandlerFixtureHandler
local function create_handler(options, state, ...)
    local handler = {args = {...}, arg_count = select("#", ...), enable_calls = 0}
    if not options.missing_enable_method then
        handler.enable_cheats = enable_cheats
    end
    state.handlers[#state.handlers + 1] = handler
    return handler
end

---@return OptionsHandlerFixturePlugin
local function load_plugin()
    return require(plugin_module)
end

---@param gc table
---@param id string
---@param gc_name string
---@return OptionsHandlerFixturePicker
local function create_picker(gc, id, gc_name)
    local Picker = require(picker_module)
    return Picker(gc, id, gc_name)
end

---@param options OptionsHandlerFixtureOptions
---@return OptionsHandlerFixtureState
local function create_state(options)
    return {
        handlers = {},
        messages = {},
        supported = options.supported or {},
        never_target = {},
        Picker = create_picker,
        load_plugin = load_plugin
    }
end

---@param options OptionsHandlerFixtureOptions
---@param state OptionsHandlerFixtureState
local function install_dependencies(options, state)
    for _, name in ipairs(dependencies) do
        package.loaded[name] = nil
    end
    package.loaded[picker_module] = nil
    package.loaded[plugin_module] = nil

    package.preload["deepcore/std/class"] = function()
        class = create_class
        return class
    end
    package.preload["deepcore/crossplot/crossplot"] = function()
        return {}
    end
    package.preload["deepcore/std/plugintargets"] = function()
        PluginTargets = {never = function() return state.never_target end}
        return PluginTargets
    end
    package.preload["eawx-plugins/options-handler/OptionsHandler"] = function()
        OptionsHandler = function(...)
            return create_handler(options, state, ...)
        end
        return OptionsHandler
    end
    package.preload["eawx-util/StoryUtil"] = function()
        StoryUtil = {ShowScreenText = function(text, duration, _, color)
            state.messages[#state.messages + 1] = {text = text, duration = duration, color = color}
        end}
        return StoryUtil
    end
end

-- Only base-mod dependencies are replaced; the picker and plugin load from mod/.
---@param options OptionsHandlerFixtureOptions
---@param test fun(state: OptionsHandlerFixtureState)
local function run(options, test)
    local loaded, preloads, globals = {}, {}, {}
    local original_path = package.path
    for name, value in pairs(package.loaded) do
        loaded[name] = value
    end
    for _, name in ipairs(dependencies) do
        preloads[name] = package.preload[name]
    end
    for _, name in ipairs(global_names) do
        globals[name] = rawget(_G, name)
    end

    local state = create_state(options)
    eaw.init("./mod")
    eaw.environment.Find_Object_Type.return_value = function(name)
        if state.supported[name] then
            return eaw.types.type(name)
        end
        return nil
    end

    local ok, err = pcall(function()
        -- A pre-existing function cannot be restored over the sandbox's mock table.
        -- Keep it outside the sandbox snapshot and restore it ourselves below.
        rawset(_G, "Find_Object_Type", nil)
        eaw.run(function()
            install_dependencies(options, state)
            state.Picker = require(picker_module)
            test(state)
        end)
    end)

    -- The abstraction layer's sandbox does not fully restore replaced entries.
    -- Restore our module cache, loaders and globals even when an assertion fails.
    for name in pairs(package.loaded) do
        if loaded[name] == nil then package.loaded[name] = nil end
    end
    for name, value in pairs(loaded) do package.loaded[name] = value end
    for _, name in ipairs(dependencies) do package.preload[name] = preloads[name] end
    for _, name in ipairs(global_names) do rawset(_G, name, globals[name]) end
    package.path = original_path
    if not ok then error(err, 0) end
end

return {run = run}
