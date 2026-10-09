--******************************************************************************
--     _______ __
--    |_     _|  |--.----.---.-.--.--.--.-----.-----.
--      |   | |     |   _|  _  |  |  |  |     |__ --|
--      |___| |__|__|__| |___._|________|__|__|_____|
--     ______
--    |   __ \.-----.--.--.-----.-----.-----.-----.
--    |      <|  -__|  |  |  -__|     |  _  |  -__|
--    |___|__||_____|\___/|_____|__|__|___  |_____|
--                                    |_____|
--*   @Author:              [TR]Pox <Pox>
--*   @Date:                2018-01-13T11:47:17+01:00
--*   @Project:             Imperial Civil War
--*   @Filename:            CategoryFilter.lua
--*   @Last modified by:    [TR]Pox
--*   @Last modified time:  2018-03-27T03:41:19+02:00
--*   @License:             This source code may only be used with explicit permission from the developers
--*   @Copyright:           © TR: Imperial Civil War Development Team
--******************************************************************************

require("PGSpawnUnits")
require("deepcore/std/class")

---@class CategoryFilter
CategoryFilter = class()

---@param galacticConquest GalacticConquest
---@param ai_dummy_handler KeyDummyLifeCycleHandler
function CategoryFilter:new(plot, galacticConquest, ai_dummy_handler, selected_planet_changed_event)
    self.EventNames = {
        "Filter_Non_Capital",
        "Filter_Capitals",
        "Filter_Structures",
        "Filter_Story",
        "Filter_Options"
    }

    self.CategoryFlags = {
        ["SELECT_NON_CAPITAL"] = {[1] = "Non_Capital_Category_Dummy", [2] = "Heavy_Frigate_Category_Dummy"},
        ["SELECT_STRUCTURE"] = {[0] = "Structure_Category_Dummy"},
        ["SELECT_STORY"] = {[0] = "Story_Category_Dummy"},
        ["SELECT_CAPITAL"] = {[3] = "Capital_Category_Dummy", [4] = "Dreadnought_Category_Dummy"},
        ["SELECT_OPTIONS"] = {[0] = "Options_Category_Dummy"}
    }

    self.Placeholder = "Placeholder_Category_Dummy"

    self.ActiveFilter = "SELECT_NON_CAPITAL"

    self.SpawnedHumanDummies = {}

    self.GalacticConquest = galacticConquest
    self.GalacticConquest.Events.PlanetOwnerChanged:attach_listener(self.on_planet_owner_changed, self)

    ---@type Planet
    self.SelectedPlanet = nil
    selected_planet_changed_event:attach_listener(self.on_selected_planet_changed, self)

    for _, eventName in pairs(self.EventNames) do
        local event = plot.Get_Event(eventName)
        if event then
            event.Set_Reward_Parameter(1, galacticConquest.HumanPlayer.Get_Faction_Name())
        end
    end

    self:register_shipyard_key_provider(ai_dummy_handler)
    self:add_ai_shipyard_dummy_sets(ai_dummy_handler)

    ---@private
    ---@type table<number, GameObjectWrapper>
    self.current_player_dummies = {}
end

function CategoryFilter:update()
    DebugMessage("CategoryFilter update Started")
    self:handle_filter_change()
    DebugMessage("CategoryFilter update Finished")
end

---@private
function CategoryFilter:handle_filter_change()
    DebugMessage("CategoryFilter HandleFilterChange Started")
    for categoryFlag, _ in pairs(self.CategoryFlags) do
        if Check_Story_Flag(self.GalacticConquest.HumanPlayer, categoryFlag, nil, true) then
            if self.ActiveFilter == categoryFlag then
                break
            end
            self.ActiveFilter = categoryFlag
            self:spawn_player_category_dummies(self.SelectedPlanet)
            break
        end
    end
    DebugMessage("CategoryFilter HandleFilterChange Finished")
end

---@private
---@param selectedPlanet Planet
function CategoryFilter:on_selected_planet_changed(selectedPlanet)
    DebugMessage("CategoryFilter OnSelectedPlanetChanged Started")
    self.SelectedPlanet = selectedPlanet
    self:spawn_player_category_dummies(self.SelectedPlanet)
    DebugMessage("CategoryFilter OnSelectedPlanetChanged Finished")
end

---@private
---@param planet Planet
function CategoryFilter:on_planet_owner_changed(planet)
    DebugMessage("CategoryFilter OnPlanetOwnerChanged Started")
    if not planet then
        return
    end

    if planet:get_owner().Is_Human() then
        if planet == self.SelectedPlanet then
            self:spawn_player_category_dummies(self.SelectedPlanet)
        end
    end
    DebugMessage("CategoryFilter OnPlanetOwnerChanged Finished")
end

---@private
---@param selectedPlanet Planet
function CategoryFilter:spawn_player_category_dummies(selectedPlanet)
    DebugMessage("CategoryFilter SpawnCategoryDummy Started")
    self:clear_player_dummies()

    if not selectedPlanet then
        return
    end

    if not selectedPlanet:get_owner().Is_Human() then
        return
    end

    if not self.ActiveFilter then
        return
    end

    local shipyard_level =
        EvaluatePerception("Shipyard_Level", selectedPlanet:get_owner(), selectedPlanet:get_game_object())
    local typeList = self:make_dummy_type_table_for_shipyard_level(shipyard_level)

    self.current_player_dummies =
        SpawnList(typeList, selectedPlanet:get_game_object(), self.GalacticConquest.HumanPlayer, false, false)
    DebugMessage("CategoryFilter SpawnCategoryDummy Finished")
end

---@private
---@param shipyard_level number
function CategoryFilter:make_dummy_type_table_for_shipyard_level(shipyard_level)
    local filter_table = self.CategoryFlags[self.ActiveFilter]
    local type_list = {}
    for required_shipyard_level, dummy_type in pairs(filter_table) do
        if shipyard_level >= required_shipyard_level then
            table.insert(type_list, dummy_type)
        end
    end

    return type_list
end

---@private
function CategoryFilter:clear_player_dummies()
    DebugMessage("CategoryFilter ClearDummies Started")
    for _, dummy in pairs(self.current_player_dummies) do
        if TestValid(dummy) then
            dummy.Despawn()
        end
    end
    DebugMessage("CategoryFilter ClearDummies Finished")
end

---@private
---@param ai_dummy_handler KeyDummyLifeCycleHandler
function CategoryFilter:register_shipyard_key_provider(ai_dummy_handler)
    ai_dummy_handler:add_key_provider_function(
        function(planet)
            local owner_key = nil
            if planet:get_owner().Is_Human() then
                owner_key = "HUMAN_PLANET"
            elseif planet:get_owner() == Find_Player("Neutral") then
                owner_key = "NEUTRAL_PLANET"
            else
                owner_key = "AI_PLANET"
            end

            if owner_key ~= "NEUTRAL_PLANET" then
                local shipyard_level = EvaluatePerception("Shipyard_Level", planet:get_owner(), planet:get_game_object())
                return owner_key .. "_SHIPYARD_LEVEL_" .. tostring(shipyard_level)
            end

        end
    )
end

---@private
---@param ai_dummy_handler KeyDummyLifeCycleHandler
function CategoryFilter:add_ai_shipyard_dummy_sets(ai_dummy_handler)
    ai_dummy_handler:add_to_dummy_set(
        "AI_PLANET",
        {
            AI_Category_Dummy = 1
        }
    )

    ai_dummy_handler:add_to_dummy_set(
        "AI_PLANET_SHIPYARD_LEVEL_1",
        {
            AI_Category_Dummy = 1
        }
    )

    ai_dummy_handler:add_to_dummy_set(
        "AI_PLANET_SHIPYARD_LEVEL_2",
        {
            AI_Category_Dummy = 1
        }
    )

    ai_dummy_handler:add_to_dummy_set(
        "AI_PLANET_SHIPYARD_LEVEL_3",
        {
            AI_Category_Dummy = 1
        }
    )

    ai_dummy_handler:add_to_dummy_set(
        "AI_PLANET_SHIPYARD_LEVEL_4",
        {
            AI_Category_Dummy = 1
        }
    )
end

return CategoryFilter
