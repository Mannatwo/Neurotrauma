
NTBP.PostersEnabled = 0 -- >0 if theres any character with the poster talent
NTBP.PostersRange = 0
NTBP.PostersPotency = 0
NTBP.Posters = {} -- contains all poster items

Hook.Add("roundStart", "NTBP.RoundStart", function()
    Timer.Wait(function()
        NTBP.FetchAllPosters()
    end,1000)
end)

function NTBP.FetchAllPosters()

    -- fetch poster items
    NTBP.Posters = {}
    for item in Item.ItemList do
        if HF.StartsWith(item.Prefab.Identifier.Value,"bpposter_") and NTBP.Posters[item]==nil then
            NTBP.Posters[item] = item
        end
    end
end
Timer.Wait(function()
    NTBP.FetchAllPosters() end,50)


NTBP.UpdateCooldown = 0
Hook.Add("think", "NTBP.update", function()
    if HF.GameIsPaused() then return end

    NTBP.UpdateCooldown = NTBP.UpdateCooldown-1
    if (NTBP.UpdateCooldown <= 0) then
        NTBP.UpdateCooldown = NT.UpdateInterval
        NTBP.Update()
    end

    NTBP.TickUpdate()
end)

function NTBP.Update()
    NTBP.PostersRange = 0
    NTBP.PostersPotency = 0

    local updateHumans = {}
    local amountHumans = 0

    -- fetchcharacters to update
    for key, character in pairs(Character.CharacterList) do
        if (character.IsHuman and not character.IsDead) then
            table.insert(updateHumans, character)
            amountHumans = amountHumans + 1
        end
    end

    -- we spread the characters out over the duration of an update so that the load isnt done all at once
    for key, character in pairs(updateHumans) do
        -- make sure theyre still alive and human
        if (character ~= nil and not character.Removed and character.IsHuman and not character.IsDead) then
            
            -- poster range and strength variables

            if HF.HasTalent(character,"ntbp_posterascension") then
                local newRange = 300
                local newPotency = 1

                if HF.HasTalent(character,"ntbp_neonpaint") then
                    newRange = newRange * 2
                end

                if HF.HasTalent(character,"ntbp_gimmickbridge") then
                    local blahajPower = HF.GetAfflictionStrength(character,"blahajpower")
                    newPotency = 1 + blahajPower/50
                end
                
                if NTBP.PostersRange < newRange then NTBP.PostersRange = newRange end
                if NTBP.PostersPotency < newPotency then NTBP.PostersPotency = newPotency end
            end

        end
    end

end


-- lets hope this doesnt affect performance too much
function NTBP.TickUpdate()
    for character in Character.CharacterList do
        if (character ~= nil and not character.Removed and character.IsHuman and not character.IsDead) then
            NTBP.TickUpdateHuman(character)
        end
    end
end

Hook.Add("NTBP.AddPoster", "NTBP.AddPoster", function (effect, deltaTime, item, targets, worldPosition)
    if NTBP.Posters[item] == nil then
        NTBP.Posters[item] = item
    end
end)