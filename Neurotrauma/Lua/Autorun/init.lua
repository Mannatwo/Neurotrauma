--if Game.IsMultiplayer and CLIENT then return end

NT = {} -- Neurotrauma
NT.Name="Neurotrauma"
NT.Version = "A1.8.4h2"
NT.VersionNum = 01080402
NT.Path = table.pack(...)[1]

-- config loading

if not File.Exists(NT.Path .. "/config.json") then

    -- create default config if there is no config file
    NT.Config = dofile(NT.Path .. "/Lua/defaultconfig.lua")
    File.Write(NT.Path .. "/config.json", json.serialize(NT.Config))

else

    -- load existing config
    NT.Config = json.parse(File.Read(NT.Path .. "/config.json"))
    
    -- add missing entries
    local defaultConfig = dofile(NT.Path .. "/Lua/defaultconfig.lua")
    for key, value in pairs(defaultConfig) do
        if NT.Config[key] == nil then
            NT.Config[key] = value
        end
    end
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

    dofile(NT.Path.."/Lua/Scripts/Server/ntcompat.lua")
    dofile(NT.Path.."/Lua/Scripts/Server/blood.lua")
    dofile(NT.Path.."/Lua/Scripts/Server/convertbloodpacks.lua")
    dofile(NT.Path.."/Lua/Scripts/Server/humanupdate.lua")
    dofile(NT.Path.."/Lua/Scripts/Server/ondamaged.lua")
    dofile(NT.Path.."/Lua/Scripts/Server/items.lua")
    dofile(NT.Path.."/Lua/Scripts/Server/onfire.lua")
    dofile(NT.Path.."/Lua/Scripts/Server/cpr.lua")
    dofile(NT.Path.."/Lua/Scripts/Server/surgerytable.lua")
    dofile(NT.Path.."/Lua/Scripts/Server/fuckbots.lua")
    dofile(NT.Path.."/Lua/Scripts/Server/lootcrates.lua")
    
    dofile(NT.Path.."/Lua/Scripts/testing.lua")
end

-- client-side code
if CLIENT then
    dofile(NT.Path.."/Lua/Scripts/Client/configgui.lua")
end