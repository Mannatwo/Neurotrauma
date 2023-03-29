
local convertedDamageTypes = {"bleeding","blunttrauma","lacerations","burn","gunshotwound","bitewounds","explosiondamage","internaldamage","foreignbody"}

local damageTypeSFXDict = {}
damageTypeSFXDict["blunttrauma"]     = "ntcsfx_cyberblunt"
damageTypeSFXDict["lacerations"]     = "ntcsfx_cyberblunt"
damageTypeSFXDict["burn"]            = "ntcsfx_welding"
damageTypeSFXDict["gunshotwound"]    = "ntcsfx_cyberblunt"
damageTypeSFXDict["bitewounds"]      = "ntcsfx_cyberbite"
damageTypeSFXDict["explosiondamage"] = "ntcsfx_cyberblunt"
damageTypeSFXDict["internaldamage"]  = "ntcsfx_cyberblunt"
damageTypeSFXDict["foreignbody"]     = "ntcsfx_cyberblunt"

Timer.Wait(function() 
NTC.AddOnDamagedHook(function (characterHealth, attackResult, hitLimb)
    
    -- automatically convert damage types
    local targetChar = characterHealth.Character
    local causeDamageTypeConversion = false
    local identifier = ""
    local sfxidentifier = nil

    for index, value in ipairs(attackResult.Afflictions) do
        if value.Strength > 1 then 
            identifier = value.Prefab.Identifier.Value

            if HF.TableContains(convertedDamageTypes,identifier) then
                causeDamageTypeConversion = true 
                if damageTypeSFXDict[identifier] ~= nil then sfxidentifier = damageTypeSFXDict[identifier] end
            end
        end
    end

    if causeDamageTypeConversion and NTCyb.HF.LimbIsCyber(targetChar,hitLimb.type) then
        if sfxidentifier ~= nil then HF.GiveItem(targetChar,sfxidentifier) end
        Timer.Wait(function() NTCyb.ConvertDamageTypes(targetChar,hitLimb.type) end,1)
    end
end)

NT.DislocateLimb = function(character,limbtype,strength)
    strength = strength or 1
    if strength > 0 and NTCyb.HF.LimbIsCyber(character,limbtype) then return end
    local limbtoaffliction = {}
    limbtoaffliction[LimbType.RightLeg] = "dislocation1"
    limbtoaffliction[LimbType.LeftLeg] = "dislocation2"
    limbtoaffliction[LimbType.RightArm] = "dislocation3"
    limbtoaffliction[LimbType.LeftArm] = "dislocation4"
    if limbtoaffliction[limbtype] == nil then return end
    HF.AddAffliction(character,limbtoaffliction[limbtype],strength)
end

NT.BreakLimb = function(character,limbtype,strength)
    strength = strength or 5
    if strength > 0 and NTCyb.HF.LimbIsCyber(character,limbtype) then return end
    local limbtoaffliction = {}
    limbtoaffliction[LimbType.RightLeg] = "rl_fracture"
    limbtoaffliction[LimbType.LeftLeg] = "ll_fracture"
    limbtoaffliction[LimbType.RightArm] = "ra_fracture"
    limbtoaffliction[LimbType.LeftArm] = "la_fracture"
    limbtoaffliction[LimbType.Head] = "h_fracture"
    limbtoaffliction[LimbType.Torso] = "t_fracture"
    if limbtoaffliction[limbtype] == nil then return end
    HF.AddAffliction(character,limbtoaffliction[limbtype],strength)
end

NT.ArteryCutLimb = function(character,limbtype,strength)
    strength=strength or 5
    if strength > 0 and NTCyb.HF.LimbIsCyber(character,limbtype) then return end
    local limbtoaffliction = {}
    limbtoaffliction[LimbType.RightLeg] = "rl_arterialcut"
    limbtoaffliction[LimbType.LeftLeg] = "ll_arterialcut"
    limbtoaffliction[LimbType.RightArm] = "ra_arterialcut"
    limbtoaffliction[LimbType.LeftArm] = "la_arterialcut"
    limbtoaffliction[LimbType.Head] = "h_arterialcut"
    limbtoaffliction[LimbType.Torso] = "t_arterialcut"
    if limbtoaffliction[limbtype] == nil then return end
    HF.AddAffliction(character,limbtoaffliction[limbtype],strength)
end

end,1)
