--if Game.IsMultiplayer and CLIENT then return end

local enabled = Game.GetEnabledContentPackages()
local isEnabled = false
for key, value in pairs(enabled) do
    if value.Name == "Neurotrauma" then
        isEnabled = true
    end
end

if isEnabled then

    NT = {} -- Neurotrauma
    NT.Name="Neurotrauma"
    NT.Version = "A1.7.1"
    NT.VersionNum = 01070100

    dofile("Mods/Neurotrauma/Lua/Scripts/helperfunctions.lua")

    -- server-side code (also run in singleplayer)
    if (Game.IsMultiplayer and SERVER) or not Game.IsMultiplayer then

        -- Version and expansion display
        Timer.Wait(function() Timer.Wait(function()
            local runstring = "\n/// Running Neurotrauma V "..NT.Version.." ///\n"

            -- add dashes
            local linelength = string.len(runstring)+4
            local i = 0
            while i < linelength do runstring=runstring.."-" i=i+1 end
            local hasAddons = #NTC.RegisteredExpansions>0

            -- add expansions
            for val in NTC.RegisteredExpansions do
                runstring = runstring.."\n+ "..(val.Name or "Unnamed expansion").." V "..(val.Version or "???")
                if val.MinNTVersion ~= nil and NT.VersionNum < (val.MinNTVersionNum or 1) then
                    runstring = runstring.."\n-- WARNING! Neurotrauma version "..val.MinNTVersion.." or higher required!"
                end
            end

            -- No expansions
            runstring=runstring.."\n"
            if not hasAddons then
                runstring = runstring.."- Not running any expansions\n"
            end

            print(runstring)
        end,1) end,1)

        dofile("Mods/Neurotrauma/Lua/Scripts/ntcompat.lua")
        dofile("Mods/Neurotrauma/Lua/Scripts/blood.lua")
        dofile("Mods/Neurotrauma/Lua/Scripts/humanupdate.lua")
        dofile("Mods/Neurotrauma/Lua/Scripts/ondamaged.lua")
        dofile("Mods/Neurotrauma/Lua/Scripts/items.lua")
        dofile("Mods/Neurotrauma/Lua/Scripts/onfire.lua")
        dofile("Mods/Neurotrauma/Lua/Scripts/cpr.lua")
        dofile("Mods/Neurotrauma/Lua/Scripts/surgerytable.lua")
        
        dofile("Mods/Neurotrauma/Lua/Scripts/testing.lua")
    end
    
    -- client-side code
    if CLIENT then
        dofile("Mods/Neurotrauma/Lua/Scripts/clientonly.lua")
    end

end