
NTSP = {} -- Neurotrauma Surgery Plus
NTSP.Name="Surgery Plus"
NTSP.Version = "A1.2.3h1"
NTSP.VersionNum = 01020301
NTSP.MinNTVersion = "A1.7.5"
NTSP.MinNTVersionNum = 01070500
NTSP.Path = table.pack(...)[1]
Timer.Wait(function() if NTC ~= nil and NTC.RegisterExpansion ~= nil then NTC.RegisterExpansion(NTSP) end end,1)

-- server-side code (also run in singleplayer)
if (Game.IsMultiplayer and SERVER) or not Game.IsMultiplayer then

    dofile(NTSP.Path.."/Lua/Scripts/humanupdate.lua")
    dofile(NTSP.Path.."/Lua/Scripts/items.lua")

    Timer.Wait(function()
        if NTC == nil then
            print("Error loading NT Surgery Plus: It appears Neurotrauma isn't loaded!")
            return
        end

        NTC.AddPreHumanUpdateHook(NTSP.PreUpdateHuman)
        NTC.AddHumanUpdateHook(NTSP.PostUpdateHuman)
    end,1)

end