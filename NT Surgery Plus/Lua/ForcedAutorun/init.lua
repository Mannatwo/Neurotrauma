if Game.IsMultiplayer and CLIENT then return end

local enabled = Game.GetEnabledContentPackages()
local isEnabled = false
for key, value in pairs(enabled) do
    if value.Name == "NT Surgery Plus" then
        isEnabled = true
    end
end

if isEnabled then

    NTSP = {} -- Neurotrauma Surgery Plus
    NTSP.Name="Surgery Plus"
    NTSP.Version = "A1.1"
    NTSP.VersionNum = 01010000
    NTSP.MinNTVersion = "A1.7.1"
    NTSP.MinNTVersionNum = 01070100
    Timer.Wait(function() if NTC ~= nil and NTC.RegisterExpansion ~= nil then NTC.RegisterExpansion(NTSP) end end,1)

    dofile("Mods/NT Surgery Plus/Lua/Scripts/humanupdate.lua")
    dofile("Mods/NT Surgery Plus/Lua/Scripts/items.lua")
    
    Timer.Wait(function()
        if NTC == nil then
            print("Error loading NT Surgery Plus: It appears Neurotrauma isn't loaded!")
            return
        end

        NTC.AddPreHumanUpdateHook(NTSP.PreUpdateHuman)
        NTC.AddHumanUpdateHook(NTSP.PostUpdateHuman)
    end,1)
end