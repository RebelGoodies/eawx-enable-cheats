---@License: MIT

---Utility to abstract API differences between major EaWX versions
CompatUtil = {}

---Displays screen text using new CoreUtil (X.0) or older StoryUtil (X.5) as a fallback
---@param message string
---@param duration number
---@param var string|GameObject?
---@param color COLOR?
function CompatUtil.ShowScreenText(message, duration, var, color)
    local success = pcall(function()
        require("eawx-util/StoryUtil")
        StoryUtil.ShowScreenText(message, duration, var, color)
    end)
    if success then return end

    pcall(function()
        require("eawx-util/CoreUtil")
        CoreUtil.ShowScreenText(message, duration, var, color)
    end)
end

return CompatUtil
