require("deepcore/std/class")
require("deepcore/crossplot/crossplot")
require("eawx-plugins/options-handler/OptionsHandler")
require("eawx-util/StoryUtil")

---@class OptionsHandlerPicker
OptionsHandlerPicker = class()

---Creates a new OptionsHandlerPicker to dynamically select the
---appropriate OptionsHandler according to the mod version
---@param gc GalacticConquest
---@param id string
---@param gc_name string
function OptionsHandlerPicker:new(gc, id, gc_name)
    self.gc = gc
    self.id = id
    self.gc_name = gc_name

    ---@private
    ---@type OptionsHandler|nil
    self.OptionsHandler = nil

    ---@type integer|nil
    self.version = nil

    ---@private
    ---@type boolean
    self.enabled_cheats = false
    self.cheats_applied = false
end

---Attempts to enable cheats for the options handler
function OptionsHandlerPicker:enable_cheats()
    self.enabled_cheats = true
    if not self.cheats_applied and
        self.OptionsHandler and
        type(self.OptionsHandler.enable_cheats) == "function"
    then
        -- X.5+ method
        self.OptionsHandler:enable_cheats()
        self.cheats_applied = true
        StoryUtil.ShowScreenText("Cheats Enabled", 7, nil, {r = 0, g = 244, b = 0})
    end
end

---Attempts to get or create an OptionsHandler by trying different mod versions
---@return OptionsHandler|nil
function OptionsHandlerPicker:get_options_handler()
    if self.OptionsHandler then
        return self.OptionsHandler
    end
    self.cheats_applied = false

    local success, result

    -- Try to pick X.6 handler with pcall
    success, result = pcall(self.pick_x6, self)
    if success and result then
        return result
    end

    --Try to pick X.5 handler with pcall
    success, result = pcall(self.pick_x5, self)
    if success and result then
        return result
    end

    -- Could not find handler
    self.version = nil
    local message = "Critical Error: Could not find appropriate OptionsHandler for this mod."
    StoryUtil.ShowScreenText(message, 300, nil, {r = 244, g = 0, b = 0})
    return nil
end

---Picks and initializes the appropriate X.5 version based on the mod
---@return OptionsHandler|nil
function OptionsHandlerPicker:pick_x5()
    self.version = 5
    if Find_Object_Type("icw") then
        -- Imperial Civil War (Thrawn's Revenge) 3.5
        self.OptionsHandler = OptionsHandler(self.gc, self.id)
    elseif Find_Object_Type("fotr") then
        -- Fall of the Republic 1.5
        self.OptionsHandler = OptionsHandler(self.gc, self.id, self.gc_name)
        self:resubscribe_ai()
    elseif Find_Object_Type("rev") then
        -- Revan's Revenge 0.5
        self.OptionsHandler = OptionsHandler(self.gc, self.gc.HumanPlayer)
    end
    if self.enabled_cheats then
        self:enable_cheats()
    end
    return self.OptionsHandler
end

---Picks and initializes the appropriate X.6 version based on the mod
---@return OptionsHandler|nil
function OptionsHandlerPicker:pick_x6()
    self.version = 6
    -- Placeholder for future X6 handlers
    if Find_Object_Type("icw") then
        -- Imperial Civil War (Thrawn's Revenge) 3.6
    elseif Find_Object_Type("fotr") then
        -- Fall of the Republic 1.6
    elseif Find_Object_Type("rev") then
        -- Revan's Revenge 0.6
    end
    if self.enabled_cheats then
        self:enable_cheats()
    end
    return self.OptionsHandler
end

---Attempts to re-subscribe the OptionsHandler AI init event
function OptionsHandlerPicker:resubscribe_ai()
    if not self.OptionsHandler then
        return
    end
    --Re-subscribe to AI initialization event without error protection
    if type(self.OptionsHandler.activate_normal_ai) == "function" then
        -- X.5+ method
        crossplot:unsubscribe("INITIALIZE_AI", self.OptionsHandler.activate_normal_ai, self.OptionsHandler)
        crossplot:subscribe("INITIALIZE_AI", self.OptionsHandler.activate_normal_ai, self.OptionsHandler, false)
    elseif type(self.OptionsHandler.activate_ai) == "function" then
        -- Pre X.5 method
        crossplot:unsubscribe("INITIALIZE_AI", self.OptionsHandler.activate_ai, self.OptionsHandler)
        crossplot:subscribe("INITIALIZE_AI", self.OptionsHandler.activate_ai, self.OptionsHandler, false)
    end
end

return OptionsHandlerPicker
