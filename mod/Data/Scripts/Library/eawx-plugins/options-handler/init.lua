require("deepcore/std/plugintargets")
require("eawx-plugins/options-handler/OptionsHandler")

return {
    type = "plugin",
    target = PluginTargets.never(),
    init = function(self, ctx)
        return OptionsHandler(ctx.galactic_conquest, ctx.id)
    end
}
