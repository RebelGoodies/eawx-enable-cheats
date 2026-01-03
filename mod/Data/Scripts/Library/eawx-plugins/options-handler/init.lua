require("deepcore/std/plugintargets")
require("eawx-plugins/options-handler/OptionsHandler")

return {
    type = "plugin",
    target = PluginTargets.never(),
    init = function(self, ctx)
        local galactic_conquest = ctx.galactic_conquest
        return OptionsHandler(galactic_conquest, galactic_conquest.HumanPlayer)
    end
}
 