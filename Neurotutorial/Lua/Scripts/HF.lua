
-- This file contains a bunch of useful functions that see heavy use in the other scripts.
NTTut.HF = {} -- Helperfunctions

function NTTut.HF.StringContains(arg1,arg2)
    if string.find(arg1, arg2) then
        return true
    end
    return false
end

function NTTut.HF.EnumerableToTable(enum)
    local res = {}
    for entry in enum do
        table.insert(res,entry)
    end
    return res
end

function NTTut.HF.RemoveCharacter(character)
    Timer.Wait(function()
        if character == nil or character.Removed then return end
    
        if SERVER then
            -- use server remove method
            Entity.Spawner.AddEntityToRemoveQueue(character)
        else
            -- use client remove method
            character.Remove()
        end
    end,1)
end