
NTBP = {} -- Neurotrauma Blahaj Plus
NTBP.Name="Blahaj Plus"
NTBP.Version = "A1.0"
NTBP.VersionNum = 01000000
NTBP.MinNTVersion = "A1.8.4"
NTBP.MinNTVersionNum = 01080400
NTBP.Path = table.pack(...)[1]
Timer.Wait(function() if NTC ~= nil and NTC.RegisterExpansion ~= nil then NTC.RegisterExpansion(NTBP) end end,1)


-- server-side code (also run in singleplayer)
if (Game.IsMultiplayer and SERVER) or not Game.IsMultiplayer then
    Timer.Wait(function()
        if NTC == nil then
            print("Error loading NT Blahaj Plus: It appears Neurotrauma isn't loaded!")
            return
        end

        --NTBP.NT = NT ~= nil

        dofile(NTBP.Path.."/Lua/Scripts/humanupdate.lua")
        dofile(NTBP.Path.."/Lua/Scripts/items.lua")
        dofile(NTBP.Path.."/Lua/Scripts/update.lua")
        dofile(NTBP.Path.."/Lua/Scripts/ondamaged.lua")
        dofile(NTBP.Path.."/Lua/Scripts/altar.lua")

        NTC.AddPreHumanUpdateHook(NTBP.PreUpdateHuman)
        NTC.AddHumanUpdateHook(NTBP.PostUpdateHuman)
    end,1)

end