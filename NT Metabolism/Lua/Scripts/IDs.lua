
NTMB.IDCharacterDict = {}

NTMB.IDCount = NTMB.CI.GetInteger("NTMB_IDCount",0)

function NTMB.GetCharacterID(character)
    local IDAfflictionStrength = HF.GetAfflictionStrength(character,"ntmb_id",0)
    if IDAfflictionStrength <= 0 then
        -- this character hasnt been assigned an ID yet, give them one and increase the ID counter
        local newID = NTMB.IDCount
        HF.SetAffliction(character,"ntmb_id",newID)
        NTMB.IDCharacterDict[newID] = character
        NTMB.IDCount = NTMB.IDCount+1

        -- prevent float rounding errors
        -- this may result in duplicate assigned IDs with like, super old characters, but its better than just
        -- giving every character the same ID after we run out of unique values
        if NTMB.IDCount > 16777210 then
            NTMB.IDCount = 0
        end

        NTMB.CI.Set("NTMB_IDCount",NTMB.IDCount)

        return newID
    end
    local res = HF.Round(IDAfflictionStrength)
    NTMB.IDCharacterDict[res] = character
    return res
end

function NTMB.GetCharacterFromID(id)
    return NTMB.IDCharacterDict[id]
end

-- make sure everyone has an ID
Hook.Add("character.created", "NTMB.AssignID", function(character)
    if not character.IsHuman then return end
    Timer.Wait(function()
        NTMB.GetCharacterID(character)
    end,1)
end)

-- fetch IDs on startup
for character in Character.CharacterList do
    if not character.IsDead then
        if character.IsHuman then
            NTMB.GetCharacterID(character)
        end
    end
end