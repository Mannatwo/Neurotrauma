
NTSP = {} -- Neurotrauma Surgery Plus
NTSP.Name="Surgery Plus"
NTSP.Version = "A1.2.6h3"
NTSP.VersionNum = 01020603
NTSP.MinNTVersion = "A1.8.7"
NTSP.MinNTVersionNum = 01080700
NTSP.Path = table.pack(...)[1]
Timer.Wait(function() if NTC ~= nil and NTC.RegisterExpansion ~= nil then NTC.RegisterExpansion(NTSP) end end,1)

-- server-side code (also run in singleplayer)
if (Game.IsMultiplayer and SERVER) or not Game.IsMultiplayer then
    Timer.Wait(function()
        if NTC == nil then
            print("Error loading NT Surgery Plus: It appears Neurotrauma isn't loaded!")
            return
        end

        dofile(NTSP.Path.."/Lua/Scripts/humanupdate.lua")
        dofile(NTSP.Path.."/Lua/Scripts/items.lua")
        dofile(NTSP.Path.."/Lua/Scripts/configdata.lua")

        NTC.AddPreHumanUpdateHook(NTSP.PreUpdateHuman)
        NTC.AddHumanUpdateHook(NTSP.PostUpdateHuman)
    end,1)

end