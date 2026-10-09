local eaw = require("test.config")

local module_name = "eawx-plugins/ui/category-filter/CategoryFilter"
local dependencies = {module_name, "deepcore/std/class", "PGSpawnUnits"}
local global_names = {
    "class", "CategoryFilter", "SpawnList", "TestValid", "EvaluatePerception", "Check_Story_Flag", "DebugMessage"
}

local function create_class()
    local cls = {}
    cls.__index = cls
    return setmetatable(cls, {__call = function(self, ...)
        local instance = setmetatable({}, self)
        instance:new(...)
        return instance
    end})
end

local function event()
    local listeners = {}
    return {
        attach_listener = function(_, callback, receiver)
            listeners[#listeners + 1] = {callback = callback, receiver = receiver}
        end,
        emit = function(_, planet)
            for _, listener in ipairs(listeners) do
                listener.callback(listener.receiver, planet)
            end
        end
    }
end

local function create_state()
    local state = {
        human = eaw.types.faction({name = "Empire", is_human = true}),
        ai = eaw.types.faction({name = "Rebel", is_human = false}),
        objects = {},
        selected = event(),
        owner_changed = event()
    }

    function state:planet(station, yard, owner)
        local planet = {station = station, yard = yard, owner = owner or self.human}
        local object = eaw.types.game_object({name = "Test_Planet", owner = planet.owner})
        object.valid = true
        object.planet = planet
        object.Get_Owner.return_value = function() return planet.owner end
        object.Get_Starbase_Level = function() return planet.station end
        planet.object = object
        function planet:get_game_object() return self.object end
        function planet:get_owner() return self.owner end
        return planet
    end

    function state:live()
        local objects = {}
        for _, object in ipairs(self.objects) do
            if object.valid then objects[#objects + 1] = object end
        end
        return objects
    end

    return state
end

local function install_dependencies(state)
    for _, name in ipairs(dependencies) do package.loaded[name] = nil end
    package.preload[module_name] = nil
    package.preload["deepcore/std/class"] = function()
        class = create_class
        return class
    end
    package.preload["PGSpawnUnits"] = function()
        SpawnList = function(types, location, owner)
            local objects = {}
            for _, name in ipairs(types) do
                local object = eaw.types.game_object({name = name, owner = owner})
                object.type_name, object.location, object.valid = name, location, true
                object.Despawn.callback = function() object.valid = false end
                objects[#objects + 1] = object
                state.objects[#state.objects + 1] = object
            end
            return objects
        end
        return true
    end
end

local function run(test)
    local loaded, preloads, globals = {}, {}, {}
    local original_path, original_cpath = package.path, package.cpath
    for name, value in pairs(package.loaded) do loaded[name] = value end
    for _, name in ipairs(dependencies) do preloads[name] = package.preload[name] end
    for _, name in ipairs(global_names) do globals[name] = rawget(_G, name) end

    local ok, err = pcall(function()
        eaw.init("./mod")
        local state = create_state()
        eaw.environment.DebugMessage = function() end
        eaw.environment.TestValid.return_value = function(object) return object.valid == true end
        eaw.environment.Check_Story_Flag.return_value = function(_, flag) return flag == state.flag end
        eaw.environment.EvaluatePerception.return_value = function(_, _, object)
            return object.planet.yard
        end
        -- Keep replaced functions outside the abstraction layer's sandbox snapshot.
        for _, name in ipairs(global_names) do rawset(_G, name, nil) end
        eaw.run(function()
            install_dependencies(state)
            local Filter = require(module_name)
            local plot = {Get_Event = function() return {Set_Reward_Parameter = function() end} end}
            local ai_handler = {
                add_key_provider_function = function() end,
                add_to_dummy_set = function() end
            }
            state.filter = Filter(plot, {
                HumanPlayer = state.human,
                Events = {PlanetOwnerChanged = state.owner_changed}
            }, ai_handler, state.selected)
            test(state)
        end)
    end)

    for name in pairs(package.loaded) do
        if loaded[name] == nil then package.loaded[name] = nil end
    end
    for name, value in pairs(loaded) do package.loaded[name] = value end
    for _, name in ipairs(dependencies) do package.preload[name] = preloads[name] end
    for _, name in ipairs(global_names) do rawset(_G, name, globals[name]) end
    package.path, package.cpath = original_path, original_cpath
    if not ok then error(err, 0) end
end

return {run = run}
