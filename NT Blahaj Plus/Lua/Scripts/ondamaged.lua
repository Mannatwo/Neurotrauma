
local afflictionsToReduceShield = {
    "bleeding",
    "blunttrauma",
    "lacerations",
    "gunshotwound",
    "bitewounds",
    "explosiondamage",
    "internaldamage"}

Timer.Wait(function() 
NTC.AddModifyingOnDamagedHook(function (characterHealth, afflictions, hitLimb)
    
    local res = {}

    -- automatically convert damage types
    local targetChar = characterHealth.Character
    local causeShieldReduction = false
    local hasShield = HF.HasAffliction(targetChar,"blahajgotbacc",1)
    local identifier = ""
    local stunAffliction = nil

    for value in afflictions do

        if hasShield then
            identifier = value.Prefab.Identifier.Value
            if HF.TableContains(afflictionsToReduceShield,identifier) then
                causeShieldReduction = true
                value.Strength = 0
            end
        end
        
        if identifier=="stun" then stunAffliction = value end
        table.insert(res,value)
    end

    if causeShieldReduction then
        if stunAffliction ~= nil then stunAffliction.Strength=0 end
        Timer.Wait(function()
            HF.AddAffliction(targetChar,"blahajgotbacc",-10)
        end,30)
    end

    return res
end)

end,1)
