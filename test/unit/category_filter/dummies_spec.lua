local fixture = require("test.support.category_filter_fixture")

local function assert_dummies(state, planet, expected)
    local names = {}
    local objects = state:live()
    for _, object in ipairs(objects) do
        names[#names + 1] = object.type_name
        assert.is_true(object.location == planet:get_game_object())
        assert.is_true(object.Get_Owner() == state.human)
    end
    table.sort(names)
    local sorted = {}
    for _, name in ipairs(expected) do sorted[#sorted + 1] = name end
    table.sort(sorted)
    assert.same(sorted, names)
    return objects
end

local function assert_retained(state, objects)
    local live = state:live()
    assert.equals(#objects, #live)
    for _, object in ipairs(objects) do
        assert.is_true(object.valid)
        local found = false
        for _, current in ipairs(live) do
            if current == object then found = true end
        end
        assert.is_true(found)
    end
end

local function assert_removed(objects)
    for _, object in ipairs(objects) do assert.is_false(object.valid) end
end

describe("category filter dummies", function()
    it("refreshes structures when the initial station completes on the selected planet", function()
        fixture.run(function(state)
            local planet = state:planet(0, 0)
            state.flag = "SELECT_STRUCTURE"
            state.filter:update()
            state.selected:emit(planet)
            local before = assert_dummies(state, planet, {"Structure_Category_Dummy"})

            planet.station = 1
            state.filter:update()
            assert_removed(before)
            local after = assert_dummies(state, planet, {"Structure_Category_Dummy"})
            state.filter:update()
            state.filter:update()
            assert_retained(state, after)
        end)
    end)

    for _, tier in ipairs({
        {name = "non-capital", flag = "SELECT_NON_CAPITAL", low = 1, high = 2,
            base = "Non_Capital_Category_Dummy", added = "Heavy_Frigate_Category_Dummy"},
        {name = "capital", flag = "SELECT_CAPITAL", low = 3, high = 4,
            base = "Capital_Category_Dummy", added = "Dreadnought_Category_Dummy"}
    }) do
        it("adds and removes eligible " .. tier.name .. " dummies as shipyards change", function()
            fixture.run(function(state)
                local planet = state:planet(1, tier.low)
                state.flag = tier.flag
                state.filter:update()
                state.selected:emit(planet)
                local before = assert_dummies(state, planet, {tier.base})

                planet.yard = tier.high
                state.filter:update()
                assert_removed(before)
                local upgraded = assert_dummies(state, planet, {tier.base, tier.added})
                state.filter:update()
                assert_retained(state, upgraded)

                planet.yard = tier.low
                state.filter:update()
                assert_removed(upgraded)
                local downgraded = assert_dummies(state, planet, {tier.base})
                state.filter:update()
                assert_retained(state, downgraded)
            end)
        end)
    end

    it("moves dummies to a newly selected planet with equal prerequisites", function()
        fixture.run(function(state)
            local first, second = state:planet(1, 2), state:planet(1, 2)
            state.selected:emit(first)
            local before = assert_dummies(state, first,
                {"Non_Capital_Category_Dummy", "Heavy_Frigate_Category_Dummy"})
            state.selected:emit(second)
            assert_removed(before)
            local after = assert_dummies(state, second,
                {"Non_Capital_Category_Dummy", "Heavy_Frigate_Category_Dummy"})
            state.filter:update()
            assert_retained(state, after)
        end)
    end)

    it("skips missing and invalid selections and resumes on a valid planet", function()
        fixture.run(function(state)
            state.filter:update()
            state.selected:emit(nil)
            state.filter:update()
            assert.equals(0, #state.objects)

            local invalid = state:planet(1, 2)
            invalid.object.valid = false
            state.selected:emit(invalid)
            state.filter:update()
            assert.equals(0, #state.objects)

            local valid = state:planet(1, 1)
            state.selected:emit(valid)
            local objects = assert_dummies(state, valid, {"Non_Capital_Category_Dummy"})
            state.filter:update()
            assert_retained(state, objects)
        end)
    end)

    it("creates player dummies after a nonhuman selected planet becomes human owned", function()
        fixture.run(function(state)
            local planet = state:planet(1, 1, state.ai)
            state.selected:emit(planet)
            state.owner_changed:emit(planet)
            state.filter:update()
            assert.equals(0, #state.objects)

            planet.owner = state.human
            state.owner_changed:emit(planet)
            local objects = assert_dummies(state, planet, {"Non_Capital_Category_Dummy"})
            state.filter:update()
            assert_retained(state, objects)
            planet.yard = 2
            state.filter:update()
            assert_removed(objects)
            assert_dummies(state, planet, {"Non_Capital_Category_Dummy", "Heavy_Frigate_Category_Dummy"})
        end)
    end)

    it("changes category without churning its new dummies on the next update", function()
        fixture.run(function(state)
            local planet = state:planet(1, 2)
            state.selected:emit(planet)
            local before = assert_dummies(state, planet,
                {"Non_Capital_Category_Dummy", "Heavy_Frigate_Category_Dummy"})
            state.flag = "SELECT_STRUCTURE"
            state.filter:update()
            assert_removed(before)
            local after = assert_dummies(state, planet, {"Structure_Category_Dummy"})
            state.filter:update()
            assert_retained(state, after)
        end)
    end)
end)
