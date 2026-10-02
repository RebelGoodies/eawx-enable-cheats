local fixture = require("test.support.options_handler_fixture")

---@return OptionsHandlerFixtureContext
local function context()
    return {galactic_conquest = {HumanPlayer = {}}, id = "test-id", gc_name = "test-campaign"}
end

---@param state OptionsHandlerFixtureState
---@param handler OptionsHandlerFixtureHandler
local function assert_enabled(state, handler)
    assert.equals(1, handler.enable_calls)
    assert.same({{
        text = "Cheats Enabled",
        duration = 7,
        color = {r = 0, g = 244, b = 0}
    }}, state.messages)
end

describe("OptionsHandlerPicker", function()
    it("waits for a handler and enables cheats only once", function()
        fixture.run({supported = {icw = true}}, function(state)
            local ctx = context()
            local picker = state.Picker(ctx.galactic_conquest, ctx.id, ctx.gc_name)
            picker:enable_cheats()
            picker:enable_cheats()
            assert.equals(0, #state.handlers)
            assert.same({}, state.messages)

            local handler = picker:get_options_handler()
            assert_enabled(state, handler)
            picker:enable_cheats()
            picker:enable_cheats()
            assert.is_true(handler == picker:get_options_handler())
            assert.equals(1, #state.handlers)
            assert_enabled(state, handler)
        end)
    end)

    it("does not enable cheats just by selecting a handler", function()
        fixture.run({supported = {fotr = true}}, function(state)
            local ctx = context()
            local picker = state.Picker(ctx.galactic_conquest, ctx.id, ctx.gc_name)
            local handler = picker:get_options_handler()
            assert.equals(0, handler.enable_calls)
            assert.same({}, state.messages)
            picker:enable_cheats()
            picker:enable_cheats()
            assert_enabled(state, handler)
        end)
    end)

    it("reports unsupported mods and can apply a deferred request after retry", function()
        fixture.run({}, function(state)
            local ctx = context()
            local picker = state.Picker(ctx.galactic_conquest, ctx.id, ctx.gc_name)
            picker:enable_cheats()
            assert.is_nil(picker:get_options_handler())
            assert.is_nil(picker.version)
            assert.equals(0, #state.handlers)
            assert.same({{
                text = "Critical Error: Could not find appropriate OptionsHandler for this mod.",
                duration = 300,
                color = {r = 244, g = 0, b = 0}
            }}, state.messages)

            state.supported.rev = true
            local handler = picker:get_options_handler()
            assert.equals(1, handler.enable_calls)
            assert.equals(2, #state.messages)
            assert.equals("Cheats Enabled", state.messages[2].text)
        end)
    end)

    it("does not claim success when the handler has no enable_cheats method", function()
        fixture.run({supported = {icw = true}, missing_enable_method = true}, function(state)
            local ctx = context()
            local picker = state.Picker(ctx.galactic_conquest, ctx.id, ctx.gc_name)
            picker:enable_cheats()
            local handler = picker:get_options_handler()
            assert.is_not_nil(handler)
            picker:enable_cheats()
            assert.same({}, state.messages)
        end)
    end)
end)
