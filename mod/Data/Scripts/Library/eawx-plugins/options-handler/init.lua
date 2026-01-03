require("deepcore/std/plugintargets")
require("eawx-plugins/options-handler/OptionsHandler")
require("eawx-plugins/options-handler/OptionsHandlerPicker")

return {
    type = "plugin",
    target = PluginTargets.never(),
    init = function(self, ctx)
        ---@type OptionsHandlerPicker
        local Picker = OptionsHandlerPicker(ctx.galactic_conquest, ctx.id, ctx.gc_name)

        ---@type OptionsHandler
        local OptionsHandler = Picker:get_options_handler()

        Picker:enable_cheats()
        return OptionsHandler
    end
}
