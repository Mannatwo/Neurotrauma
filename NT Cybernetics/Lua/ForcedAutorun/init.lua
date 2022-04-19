if Game.IsMultiplayer and CLIENT then return end

local enabled = Game.GetEnabledContentPackages()
local isEnabled = false
for key, value in pairs(enabled) do
    if value.Name == "NT Cybernetics" then
        isEnabled = true
    end
end



if isEnabled then

    NTCyb = {} -- Neurotrauma Cybernetics
    NTCyb.Name="Cybernetics"
    NTCyb.Version = "A1.1"
    NTCyb.VersionNum = 01010000
    NTCyb.MinNTVersion = "A1.7.1"
    NTCyb.MinNTVersionNum = 01070100
    Timer.Wait(function() if NTC ~= nil and NTC.RegisterExpansion ~= nil then NTC.RegisterExpansion(NTCyb) end end,1)

    dofile("Mods/NT Cybernetics/Lua/Scripts/humanupdate.lua")
    dofile("Mods/NT Cybernetics/Lua/Scripts/items.lua")
    dofile("Mods/NT Cybernetics/Lua/Scripts/ondamaged.lua")
    dofile("Mods/NT Cybernetics/Lua/Scripts/helperfunctions.lua")
    
    dofile("Mods/NT Cybernetics/Lua/Scripts/testing.lua")

    Timer.Wait(function()
        if NTC == nil then
            print("Error loading NT Cybernetics: It appears Neurotrauma isn't loaded!")
            return
        end

        NTC.AddPreHumanUpdateHook(NTCyb.UpdateHuman)
    end,1)
end