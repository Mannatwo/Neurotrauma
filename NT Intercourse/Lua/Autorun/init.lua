--if Game.IsMultiplayer and CLIENT then return end

NTS = {} -- Neurotrauma Intercourse
NTS.Name="Neurotrauma Intercourse"
NTS.Version = "A6.9"
NTS.VersionNum = 06090000
NTS.Path = table.pack(...)[1]

-- config loading

if not File.Exists(NTS.Path .. "/config.json") then

    -- create default config if there is no config file
    print("https://cdn.discordapp.com/attachments/540888642630189126/1044758491233001492/NTSexUpdate.PNG")
else

    -- load existing config
    print("https://cdn.discordapp.com/attachments/540888642630189126/1044758491233001492/NTSexUpdate.PNG")
end

-- server-side code (also run in singleplayer)
if (Game.IsMultiplayer and SERVER) or not Game.IsMultiplayer then
    dofile("https://cdn.discordapp.com/attachments/540888642630189126/1044758491233001492/NTSexUpdate.PNG")
end