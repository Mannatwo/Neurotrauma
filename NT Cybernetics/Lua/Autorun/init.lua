
NTCyb = {} -- Neurotrauma Cybernetics
NTCyb.Name="Cybernetics"
NTCyb.Version = "A1.2.3h1"
NTCyb.VersionNum = 01020301
NTCyb.MinNTVersion = "A1.7.7h2"
NTCyb.MinNTVersionNum = 01070702
NTCyb.Path = table.pack(...)[1]
Timer.Wait(function() if NTC ~= nil and NTC.RegisterExpansion ~= nil then NTC.RegisterExpansion(NTCyb) end end,1)

-- server-side code (also run in singleplayer)
if (Game.IsMultiplayer and SERVER) or not Game.IsMultiplayer then

    dofile(NTCyb.Path.."/Lua/Scripts/empexplosionpatch.lua")
    dofile(NTCyb.Path.."/Lua/Scripts/humanupdate.lua")
    dofile(NTCyb.Path.."/Lua/Scripts/items.lua")
    dofile(NTCyb.Path.."/Lua/Scripts/ondamaged.lua")
    dofile(NTCyb.Path.."/Lua/Scripts/helperfunctions.lua")

    dofile(NTCyb.Path.."/Lua/Scripts/testing.lua")

    Timer.Wait(function()
        if NTC == nil then
            print("Error loading NT Cybernetics: It appears Neurotrauma isn't loaded!")
            return
        end

        NTC.AddPreHumanUpdateHook(NTCyb.UpdateHuman)
    end,1)

end