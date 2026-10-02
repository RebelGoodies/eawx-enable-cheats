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

describe("options handler plugin", function()
    for _, mod in ipairs({
        {name = "TR 3.5", marker = "icw"},
        {name = "FotR 1.5", marker = "fotr"},
        {name = "Rev 0.5", marker = "rev"}
    }) do
        it("constructs and enables the " .. mod.name .. " handler", function()
            fixture.run({supported = {[mod.marker] = true}}, function(state)
                local ctx = context()
                local plugin = state.load_plugin()
                assert.equals("plugin", plugin.type)
                assert.is_true(plugin.target == state.never_target)
                local handler = plugin:init(ctx)
                assert.equals(1, #state.handlers)
                assert.is_true(handler == state.handlers[1])
                assert.is_true(handler.args[1] == ctx.galactic_conquest)
                if mod.marker == "rev" then
                    assert.equals(2, handler.arg_count)
                    assert.is_true(handler.args[2] == ctx.galactic_conquest.HumanPlayer)
                else
                    assert.is_true(handler.args[2] == ctx.id)
                    assert.equals(mod.marker == "fotr" and 3 or 2, handler.arg_count)
                    if mod.marker == "fotr" then assert.equals(ctx.gc_name, handler.args[3]) end
                end
                assert_enabled(state, handler)
            end)
        end)
    end

    it("returns nil and reports an error for an unsupported mod", function()
        fixture.run({}, function(state)
            assert.is_nil(state.load_plugin():init(context()))
            assert.equals(0, #state.handlers)
            assert.equals(1, #state.messages)
            assert.equals("Critical Error: Could not find appropriate OptionsHandler for this mod.", state.messages[1].text)
        end)
    end)
end)
