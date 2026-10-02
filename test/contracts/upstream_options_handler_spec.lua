local fixture = require("test.support.upstream_options_handler_fixture")
local root = os.getenv("WORKSHOP_EAW")
local mods = {
    {name = "Thrawn's Revenge", id = "1125571106", marker = "icw"},
    {name = "Fall of the Republic", id = "1976399102", marker = "fotr"},
    {name = "Revan's Revenge", id = "3417277973", marker = "rev"}
}

---@return string[]
local function expected_cheats(mod)
    local names = {
        "Cheat_Disable_AI", "Cheat_Give_Credits", "Cheat_Give_Unit", "Cheat_Give_Vision",
        "Cheat_Influence", "Cheat_Infra_And_Discount", "Cheat_Kill_All",
        "Cheat_Turn_Off_Crews", "Cheat_Victory"
    }
    if mod.marker == "icw" then names[#names + 1] = "Cheat_Government" end
    return names
end

describe("upstream OptionsHandler contracts", function()
    if root == nil then
        pending("needs WORKSHOP_EAW to locate the installed mods")
        return
    end

    for _, mod in ipairs(mods) do
        it("binds constructor state and invokes real enable_cheats for " .. mod.name, function()
            fixture.run(root, mod, function(state)
                local picker = state.Picker(state.gc, "contract-id", "contract-campaign")
                assert.is_true(picker.gc == state.gc)
                assert.equals("contract-id", picker.id)
                assert.equals("contract-campaign", picker.gc_name)
                local handler = picker:get_options_handler()
                assert.is_true(handler.galactic_conquest == state.gc)
                assert.is_true(handler.human_player == state.player)
                if mod.marker ~= "rev" then
                    assert.equals("contract-id", handler.gc_id)
                    assert.equals("TEST_FACTION", handler.human_name)
                end
                if mod.marker == "fotr" then assert.equals("contract-campaign", handler.gc_name) end
                assert.same({}, state.unlocks)
                assert.same({}, state.messages)
                assert.equals("function", type(handler.enable_cheats))
                picker:enable_cheats()
                local unlocked, first_unlocks = {}, {}
                for index, name in ipairs(state.unlocks) do
                    unlocked[name] = true
                    first_unlocks[index] = name
                end
                for _, name in ipairs(expected_cheats(mod)) do
                    assert.is_true(unlocked[name], "Missing required cheat unlock: " .. name)
                end
                picker:enable_cheats()
                assert.same(first_unlocks, state.unlocks)
                assert.same({"Cheats Enabled"}, state.messages)
            end)
        end)

        for _, fails in ipairs({false, true}) do
            it("restores modules and globals for " .. mod.name .. " after " .. (fails and "failure" or "success"), function()
                local globals, loaded, preloads = {}, {}, {}
                for key, value in pairs(_G) do globals[key] = value end
                for key, value in pairs(package.loaded) do loaded[key] = value end
                for key, value in pairs(package.preload) do preloads[key] = value end
                local path = package.path
                local reached_callback = false
                local ok, err = pcall(function()
                    fixture.run(root, mod, function()
                        reached_callback = true
                        if fails then error("intentional upstream fixture failure", 0) end
                    end)
                end)
                assert.equals(path, package.path)
                assert.same(loaded, package.loaded)
                assert.same(preloads, package.preload)
                for key, value in pairs(globals) do assert.is_true(rawget(_G, key) == value) end
                for key in pairs(_G) do assert.is_not_nil(globals[key]) end
                if not reached_callback then error(err, 0) end
                assert.equals(not fails, ok)
                if fails then assert.matches("intentional upstream fixture failure", tostring(err), 1, true) end
            end)
        end
    end
end)
