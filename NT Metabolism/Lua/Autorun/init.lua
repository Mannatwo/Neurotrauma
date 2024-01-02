
NTMB = {} -- Neurotrauma Metabolism
NTMB.Name="Metabolism"
NTMB.Version = "A1.0"
NTMB.VersionNum = 01000000
NTMB.MinNTVersion = "A1.8.4"
NTMB.MinNTVersionNum = 01080400
NTMB.Path = table.pack(...)[1]
Timer.Wait(function() if NTC ~= nil and NTC.RegisterExpansion ~= nil then NTC.RegisterExpansion(NTMB) end end,1)


-- server-side code (also run in singleplayer)
if (Game.IsMultiplayer and SERVER) or not Game.IsMultiplayer then
    Timer.Wait(function()
        if NTC == nil then
            print("Error loading NT Metabolism: It appears the medical system is undercooked!")
            return
        end

        dofile(NTMB.Path.."/Lua/Scripts/campaignInterface.lua") -- for storing and reading data from campaign meta data
    
        dofile(NTMB.Path.."/Lua/Scripts/nutrients.lua")
        dofile(NTMB.Path.."/Lua/Scripts/ingredients.lua")
        dofile(NTMB.Path.."/Lua/Scripts/metabolism.lua")
        dofile(NTMB.Path.."/Lua/Scripts/IDs.lua")
        dofile(NTMB.Path.."/Lua/Scripts/configdata.lua")
        dofile(NTMB.Path.."/Lua/Scripts/items.lua")
        dofile(NTMB.Path.."/Lua/Scripts/machines.lua")
        dofile(NTMB.Path.."/Lua/Scripts/eating.lua")
        dofile(NTMB.Path.."/Lua/Scripts/cuttingboard.lua")
        dofile(NTMB.Path.."/Lua/Scripts/recipes.lua")


    end,1)
end