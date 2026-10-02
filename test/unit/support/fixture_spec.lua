local fixture = require("test.support.options_handler_fixture")

describe("options handler fixture isolation", function()
    for _, fails in ipairs({false, true}) do
        it("restores the existing Find_Object_Type after " .. (fails and "failure" or "success"), function()
            local original = rawget(_G, "Find_Object_Type")
            local sentinel = function() return "outside fixture" end
            rawset(_G, "Find_Object_Type", sentinel)
            local reached_callback = false
            local ok, err = pcall(function()
                fixture.run({supported = {icw = true}}, function()
                    reached_callback = true
                    assert.is_not_nil(Find_Object_Type("icw"))
                    assert.is_nil(Find_Object_Type("fotr"))
                    if fails then error("intentional fixture failure", 0) end
                end)
            end)
            local restored = rawget(_G, "Find_Object_Type")
            rawset(_G, "Find_Object_Type", original)

            assert.is_true(reached_callback)
            assert.is_true(restored == sentinel)
            assert.equals(not fails, ok)
            if fails then assert.matches("intentional fixture failure", tostring(err), 1, true) end
        end)
    end
end)
