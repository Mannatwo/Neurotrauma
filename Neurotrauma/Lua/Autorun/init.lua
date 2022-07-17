--if Game.IsMultiplayer and CLIENT then return end

NT = {} -- Neurotrauma
NT.Name="Neurotrauma"
NT.Version = "A1.7.11"
NT.VersionNum = 01071100
NT.Path = table.pack(...)[1]

-- config loading

-- create default config if there is no config file
if not File.Exists(NT.Path .. "/config.json") then
    NT.Config = dofile(NT.Path .. "/Lua/defaultconfig.lua")
    File.Write(NT.Path .. "/config.json", json.serialize(NT.Config))
else
    NT.Config = json.parse(File.Read(NT.Path .. "/config.json"))
end

dofile(NT.Path.."/Lua/Scripts/helperfunctions.lua")

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

    dofile(NT.Path.."/Lua/Scripts/ntcompat.lua")
    dofile(NT.Path.."/Lua/Scripts/blood.lua")
    dofile(NT.Path.."/Lua/Scripts/convertbloodpacks.lua")
    dofile(NT.Path.."/Lua/Scripts/humanupdate.lua")
    dofile(NT.Path.."/Lua/Scripts/ondamaged.lua")
    dofile(NT.Path.."/Lua/Scripts/items.lua")
    dofile(NT.Path.."/Lua/Scripts/onfire.lua")
    dofile(NT.Path.."/Lua/Scripts/cpr.lua")
    dofile(NT.Path.."/Lua/Scripts/surgerytable.lua")
    
    dofile(NT.Path.."/Lua/Scripts/testing.lua")
end

-- client-side code
if CLIENT then
    dofile(NT.Path.."/Lua/Scripts/clientonly.lua")
    dofile(NT.Path.."/Lua/Scripts/configgui.lua")
end