
Hook.Add("character.applyDamage", "NT.ondamaged", function (characterHealth, attackResult, hitLimb)
    
    if -- invalid attack data, don't do anything
        characterHealth == nil or 
        characterHealth.Character == nil or 
        characterHealth.Character.IsDead or 
        not characterHealth.Character.IsHuman or 
        attackResult == nil or 
        attackResult.Afflictions == nil or
        #attackResult.Afflictions <= 0 or
        hitLimb == nil
    then return end
    
    local identifier = ""
    local methodtorun = nil
    for index, value in ipairs(attackResult.Afflictions) do
        -- execute fitting method, if available
        identifier = value.Prefab.Identifier
        methodtorun = NT.OnDamagedMethods[identifier]
        if methodtorun ~= nil then 
            methodtorun(characterHealth.Character,value.Strength,hitLimb.type)
        end
    end

    -- ntc
    -- ondamaged hooks
    for key, val in pairs(NTC.OnDamagedHooks) do
        val(characterHealth, attackResult, hitLimb)
    end
end)

NT.OnDamagedMethods = {}

local function HasLungs(c) return not HF.HasAffliction(c,"lungremoved") end
local function HasHeart(c) return not HF.HasAffliction(c,"heartremoved") end

-- cause foreign bodies, rib fractures, pneumothorax, tamponade, internal bleeding, fractures, neurotrauma
NT.OnDamagedMethods.gunshotwound = function(character,strength,limbtype) 
    limbtype = HF.NormalizeLimbType(limbtype)

    if HF.Chance(0.75) then
        HF.AddAfflictionLimb(character,"foreignbody",limbtype,strength/3)
    end

    -- torso specific
    if strength >= 1 and limbtype==LimbType.Torso then
        local hitOrgan = false
        if HF.Chance(0.3*NTC.GetMultiplier(character,"anyfracturechance")) then
            HF.AddAfflictionLimb(character,"t_fracture",limbtype,5) end
        if HasLungs(character) and HF.Chance(0.3*NTC.GetMultiplier(character,"pneumothoraxchance")) then
            HF.AddAfflictionLimb(character,"pneumothorax",limbtype,5)
            HF.AddAffliction(character,"lungdamage",strength) 
            HF.AddAffliction(character,"organdamage",strength/4)
            hitOrgan=true
        end
        if HasHeart(character) and hitOrgan == false and strength >= 5 and HF.Chance(strength/50*NTC.GetMultiplier(character,"tamponadechance")) then
            HF.AddAfflictionLimb(character,"tamponade",limbtype,5) 
            HF.AddAffliction(character,"heartdamage",strength)
            HF.AddAffliction(character,"organdamage",strength/4)
            hitOrgan=true
        end
        if strength >= 5 then
            HF.AddAfflictionLimb(character,"internalbleeding",limbtype,strength*HF.RandomRange(0.3,0.6)) end

        -- liver and kidney damage
        if hitOrgan==false and strength >= 2 and HF.Chance(0.5) then
            HF.AddAfflictionLimb(character,"organdamage",limbtype,strength/4)
            if HF.Chance(0.5) then
                HF.AddAffliction(character,"liverdamage",strength)
            else
                HF.AddAffliction(character,"kidneydamage",strength)
            end
        end
    end

    -- head
    if strength >= 1 and limbtype==LimbType.Head then
        if HF.Chance(strength/90*NTC.GetMultiplier(character,"anyfracturechance")) then
            HF.AddAfflictionLimb(character,"h_fracture",limbtype,5) end
        if strength >= 5 and HF.Chance(0.7) then
            HF.AddAfflictionLimb(character,"cerebralhypoxia",limbtype,strength*HF.RandomRange(0.1,0.4)) end
    end

    -- extremities
    if strength >= 1 and HF.LimbIsExtremity(limbtype) then
        if not NT.LimbIsBroken(character,limbtype) and HF.Chance(strength/60*NTC.GetMultiplier(character,"anyfracturechance")) then
            NT.BreakLimb(character,limbtype)
        elseif NT.LimbIsBroken(character,limbtype) and not NT.LimbIsAmputated(character,limbtype) and HF.Chance(strength/60*NTC.GetMultiplier(character,"traumamputatechance")) then
            NT.TraumamputateLimb(character,limbtype) end
    end
end

-- cause foreign bodies, rib fractures, pneumothorax, internal bleeding, concussion, fractures
NT.OnDamagedMethods.explosiondamage = function(character,strength,limbtype) 
    limbtype = HF.NormalizeLimbType(limbtype)

    if HF.Chance(0.75) then
        HF.AddAfflictionLimb(character,"foreignbody",limbtype,strength/3)
    end

    -- torso specific
    if strength >= 1 and limbtype==LimbType.Torso then
        if strength >= 10 and HF.Chance(strength/50*NTC.GetMultiplier(character,"anyfracturechance")) then
            HF.AddAfflictionLimb(character,"t_fracture",limbtype,5) end
        if HasLungs(character) and strength >= 5 and HF.Chance(strength/50*NTC.GetMultiplier(character,"pneumothoraxchance")) then
            HF.AddAfflictionLimb(character,"pneumothorax",limbtype,5) end
        if strength >= 5 then
            HF.AddAfflictionLimb(character,"internalbleeding",limbtype,strength*HF.RandomRange(0.2,0.5)) end
    end

    -- head
    if strength >= 1 and limbtype==LimbType.Head then
        if strength >= 15 and HF.Chance(math.min(strength/60,0.7)) then
            HF.AddAfflictionLimb(character,"concussion",limbtype,10) end
        if strength >= 15 and HF.Chance(math.min(strength/60,0.7)*NTC.GetMultiplier(character,"anyfracturechance")) then
            HF.AddAfflictionLimb(character,"h_fracture",limbtype,5) end
        if strength >= 15 and HF.Chance(math.min(strength/60,0.7)*NTC.GetMultiplier(character,"anyfracturechance")) then
            HF.AddAfflictionLimb(character,"n_fracture",limbtype,5) end
        if strength >= 25 and HF.Chance(0.25) then
            HF.AddAfflictionLimb(character,"gate_ta_h",limbtype,5) end
    end

    -- extremities
    if strength >= 1 and HF.LimbIsExtremity(limbtype) then
        if not NT.LimbIsBroken(character,limbtype) and HF.Chance(strength/60*NTC.GetMultiplier(character,"anyfracturechance")) then
            NT.BreakLimb(character,limbtype)
        elseif NT.LimbIsBroken(character,limbtype) and not NT.LimbIsAmputated(character,limbtype) and HF.Chance(strength/60*NTC.GetMultiplier(character,"traumamputatechance")) then
            NT.TraumamputateLimb(character,limbtype) end
        if HF.Chance(0.35) then
            NT.DislocateLimb(character,limbtype) end
    end
end

-- cause rib fractures, pneumothorax, internal bleeding, concussion, fractures
NT.OnDamagedMethods.bitewounds = function(character,strength,limbtype) 
    limbtype = HF.NormalizeLimbType(limbtype)

    -- torso specific
    if strength >= 1 and limbtype==LimbType.Torso then
        if strength >= 10 and HF.Chance((strength-10)/50*NTC.GetMultiplier(character,"anyfracturechance")) then
            HF.AddAfflictionLimb(character,"t_fracture",limbtype,5) end
        if HasLungs(character) and strength >= 5 and HF.Chance((strength-5)/50*NTC.GetMultiplier(character,"pneumothoraxchance")) then
            HF.AddAfflictionLimb(character,"pneumothorax",limbtype,5) end
        if strength >= 5 then
            HF.AddAfflictionLimb(character,"internalbleeding",limbtype,strength*HF.RandomRange(0.2,0.5)) end
    end

    -- head
    if strength >= 1 and limbtype==LimbType.Head then
        if strength >= 15 and HF.Chance(math.min(strength/60,0.7)) then
            HF.AddAfflictionLimb(character,"concussion",limbtype,10) end
        if strength >= 15 and HF.Chance(math.min((strength-10)/60,0.7)*NTC.GetMultiplier(character,"anyfracturechance")) then
            HF.AddAfflictionLimb(character,"h_fracture",limbtype,5) end
    end

    -- extremities
    if strength >= 1 and HF.LimbIsExtremity(limbtype) then
        if not NT.LimbIsBroken(character,limbtype) and HF.Chance((strength-5)/60*NTC.GetMultiplier(character,"anyfracturechance")) then
            NT.BreakLimb(character,limbtype)
        elseif NT.LimbIsBroken(character,limbtype) and not NT.LimbIsAmputated(character,limbtype) and HF.Chance((strength-5)/60*NTC.GetMultiplier(character,"traumamputatechance")) then
            NT.TraumamputateLimb(character,limbtype) end
    end
end

-- cause rib fractures, pneumothorax, tamponade, internal bleeding, fractures
NT.OnDamagedMethods.lacerations = function(character,strength,limbtype) 
    limbtype = HF.NormalizeLimbType(limbtype)

    -- torso specific
    if strength >= 1 and limbtype==LimbType.Torso then
        if strength >= 10 and HF.Chance((strength-10)/50*NTC.GetMultiplier(character,"anyfracturechance")) then
            HF.AddAfflictionLimb(character,"t_fracture",limbtype,5) end
        if HasLungs(character) and strength >= 5 and HF.Chance((strength-5)/50*NTC.GetMultiplier(character,"pneumothoraxchance")) then
            HF.AddAfflictionLimb(character,"pneumothorax",limbtype,5) end
        if HasHeart(character) and strength >= 5 and HF.Chance((strength-5)/50*NTC.GetMultiplier(character,"tamponadechance")) then
            HF.AddAfflictionLimb(character,"tamponade",limbtype,5) end
        if strength >= 5 then
            HF.AddAfflictionLimb(character,"internalbleeding",limbtype,strength*HF.RandomRange(0.2,0.5)) end
    end

    -- head
    if strength >= 1 and limbtype==LimbType.Head then
        if strength >= 15 and HF.Chance(math.min((strength-15)/60,0.7)*NTC.GetMultiplier(character,"anyfracturechance")) then
            HF.AddAfflictionLimb(character,"h_fracture",limbtype,5) end
    end

    -- extremities
    if strength >= 1 and HF.LimbIsExtremity(limbtype) then
        if not NT.LimbIsBroken(character,limbtype) and HF.Chance((strength-5)/60*NTC.GetMultiplier(character,"anyfracturechance")) then
            NT.BreakLimb(character,limbtype)
        elseif NT.LimbIsBroken(character,limbtype) and not NT.LimbIsAmputated(character,limbtype) and HF.Chance(strength/60*NTC.GetMultiplier(character,"traumamputatechance")) then
            NT.TraumamputateLimb(character,limbtype) end
    end
end

-- cause rib fractures, organ damage, pneumothorax, concussion, fractures, neurotrauma
NT.OnDamagedMethods.blunttrauma = function(character,strength,limbtype) 
    limbtype = HF.NormalizeLimbType(limbtype)

    -- torso
    if strength >= 1 and limbtype==LimbType.Torso then
        if HF.Chance(strength/50*NTC.GetMultiplier(character,"anyfracturechance")) then
        HF.AddAfflictionLimb(character,"t_fracture",limbtype,5) end

        HF.AddAfflictionLimb(character,"lungdamage",limbtype,strength*HF.RandomRange(0,1))
        HF.AddAfflictionLimb(character,"heartdamage",limbtype,strength*HF.RandomRange(0,1))
        HF.AddAfflictionLimb(character,"liverdamage",limbtype,strength*HF.RandomRange(0,1))
        HF.AddAfflictionLimb(character,"kidneydamage",limbtype,strength*HF.RandomRange(0,1))
        HF.AddAfflictionLimb(character,"organdamage",limbtype,strength*HF.RandomRange(0,1))

        if HasLungs(character) and strength >= 5 and HF.Chance(strength/50*NTC.GetMultiplier(character,"pneumothoraxchance")) then
            HF.AddAfflictionLimb(character,"pneumothorax",limbtype,5) end
    end

    -- head
    if strength >= 1 and limbtype==LimbType.Head then
        if strength >= 15 and HF.Chance(math.min(strength/60,0.7)) then
            HF.AddAfflictionLimb(character,"concussion",limbtype,10) end
        if strength >= 15 and HF.Chance(math.min((strength-10)/60,0.7)*NTC.GetMultiplier(character,"anyfracturechance")) then
            HF.AddAfflictionLimb(character,"h_fracture",limbtype,5) end
        if strength >= 15 and HF.Chance(math.min((strength-10)/60,0.7)*NTC.GetMultiplier(character,"anyfracturechance")) then
            HF.AddAfflictionLimb(character,"n_fracture",limbtype,5) end
        if strength >= 5 and HF.Chance(0.7) then
            HF.AddAfflictionLimb(character,"cerebralhypoxia",limbtype,strength*HF.RandomRange(0.1,0.4)) end
    end

    -- extremities
    if strength >= 1 and HF.LimbIsExtremity(limbtype) then
        if not NT.LimbIsBroken(character,limbtype) and HF.Chance((strength-2)/60*NTC.GetMultiplier(character,"anyfracturechance")) then
            NT.BreakLimb(character,limbtype)
        elseif strength > 15 and NT.LimbIsBroken(character,limbtype) and not NT.LimbIsAmputated(character,limbtype) and HF.Chance(strength/100*NTC.GetMultiplier(character,"traumamputatechance")) then
            NT.TraumamputateLimb(character,limbtype) end
        if HF.Chance(HF.Clamp(strength/80,0.1,0.5)) then
            NT.DislocateLimb(character,limbtype) end
    end
end

-- cause rib fractures, organ damage, pneumothorax, concussion, fractures
NT.OnDamagedMethods.internaldamage = function(character,strength,limbtype) 
    limbtype = HF.NormalizeLimbType(limbtype)

    -- torso
    if strength >= 1 and limbtype==LimbType.Torso then
        if HF.Chance((strength-5)/50*NTC.GetMultiplier(character,"anyfracturechance")) then
        HF.AddAfflictionLimb(character,"t_fracture",limbtype,5) end

        HF.AddAfflictionLimb(character,"lungdamage",limbtype,strength*HF.RandomRange(0,1))
        HF.AddAfflictionLimb(character,"heartdamage",limbtype,strength*HF.RandomRange(0,1))
        HF.AddAfflictionLimb(character,"liverdamage",limbtype,strength*HF.RandomRange(0,1))
        HF.AddAfflictionLimb(character,"kidneydamage",limbtype,strength*HF.RandomRange(0,1))
        HF.AddAfflictionLimb(character,"organdamage",limbtype,strength*HF.RandomRange(0,1))
    
        if HasLungs(character) and strength >= 5 and HF.Chance((strength-5)/50*NTC.GetMultiplier(character,"pneumothoraxchance")) then
            HF.AddAfflictionLimb(character,"pneumothorax",limbtype,5) end
    end

    -- head
    if strength >= 1 and limbtype==LimbType.Head then
        if strength >= 15 and HF.Chance(math.min(strength/60,0.7)) then
            HF.AddAfflictionLimb(character,"concussion",limbtype,10) end
        if strength >= 15 and HF.Chance(math.min((strength-5)/60,0.7)*NTC.GetMultiplier(character,"anyfracturechance")) then
            HF.AddAfflictionLimb(character,"h_fracture",limbtype,5) end
        if strength >= 15 and HF.Chance(math.min((strength-5)/60,0.7)*NTC.GetMultiplier(character,"anyfracturechance")) then
            HF.AddAfflictionLimb(character,"n_fracture",limbtype,5) end
    end

    -- extremities
    if strength >= 1 and HF.LimbIsExtremity(limbtype) then
        if not NT.LimbIsBroken(character,limbtype) and HF.Chance((strength-5)/60*NTC.GetMultiplier(character,"anyfracturechance")) then
            NT.BreakLimb(character,limbtype)
        elseif strength > 10 and NT.LimbIsBroken(character,limbtype) and not NT.LimbIsAmputated(character,limbtype) and HF.Chance((strength-10)/60*NTC.GetMultiplier(character,"traumamputatechance")) then
            NT.TraumamputateLimb(character,limbtype) end
        if HF.Chance(0.25) then
            NT.DislocateLimb(character,limbtype) end
    end
end


function NT.DislocateLimb(character,limbtype)
    local limbtoaffliction = {}
    limbtoaffliction[LimbType.RightLeg] = "dislocation1"
    limbtoaffliction[LimbType.LeftLeg] = "dislocation2"
    limbtoaffliction[LimbType.RightArm] = "dislocation3"
    limbtoaffliction[LimbType.LeftArm] = "dislocation4"
    if limbtoaffliction[limbtype] == nil then return end
    HF.AddAfflictionLimb(character,limbtoaffliction[limbtype],limbtype,1)
end

function NT.BreakLimb(character,limbtype)
    local limbtoaffliction = {}
    limbtoaffliction[LimbType.RightLeg] = "rl_fracture"
    limbtoaffliction[LimbType.LeftLeg] = "ll_fracture"
    limbtoaffliction[LimbType.RightArm] = "ra_fracture"
    limbtoaffliction[LimbType.LeftArm] = "la_fracture"
    if limbtoaffliction[limbtype] == nil then return end
    HF.AddAfflictionLimb(character,limbtoaffliction[limbtype],limbtype,5)
end

function NT.TraumamputateLimb(character,limbtype)
    local limbtoaffliction = {}
    limbtoaffliction[LimbType.RightLeg] = "gate_ta_rl"
    limbtoaffliction[LimbType.LeftLeg] = "gate_ta_ll"
    limbtoaffliction[LimbType.RightArm] = "gate_ta_ra"
    limbtoaffliction[LimbType.LeftArm] = "gate_ta_la"
    if limbtoaffliction[limbtype] == nil then return end
    HF.AddAfflictionLimb(character,limbtoaffliction[limbtype],limbtype,10)
end

function NT.TraumamputateLimbMinusItem(character,limbtype)
    local limbtoaffliction = {}
    limbtoaffliction[LimbType.RightLeg] = "gate_ta_rl_2"
    limbtoaffliction[LimbType.LeftLeg] = "gate_ta_ll_2"
    limbtoaffliction[LimbType.RightArm] = "gate_ta_ra_2"
    limbtoaffliction[LimbType.LeftArm] = "gate_ta_la_2"
    if limbtoaffliction[limbtype] == nil then return end
    HF.AddAfflictionLimb(character,limbtoaffliction[limbtype],limbtype,10)
end


function NT.LimbIsDislocated(character,limbtype)
    local limbtoaffliction = {}
    limbtoaffliction[LimbType.RightLeg] = "dislocation1"
    limbtoaffliction[LimbType.LeftLeg] = "dislocation2"
    limbtoaffliction[LimbType.RightArm] = "dislocation3"
    limbtoaffliction[LimbType.LeftArm] = "dislocation4"
    if limbtoaffliction[limbtype] == nil then return false end
    return HF.HasAfflictionLimb(character,limbtoaffliction[limbtype],limbtype,1)
end

function NT.LimbIsBroken(character,limbtype)
    local limbtoaffliction = {}
    limbtoaffliction[LimbType.RightLeg] = "rl_fracture"
    limbtoaffliction[LimbType.LeftLeg] = "ll_fracture"
    limbtoaffliction[LimbType.RightArm] = "ra_fracture"
    limbtoaffliction[LimbType.LeftArm] = "la_fracture"
    if limbtoaffliction[limbtype] == nil then return false end
    return HF.HasAfflictionLimb(character,limbtoaffliction[limbtype],limbtype,1)
end

function NT.LimbIsAmputated(character,limbtype)
    return 
        NT.LimbIsTraumaticallyAmputated(character,limbtype) or
        NT.LimbIsSurgicallyAmputated(character,limbtype)
end

function NT.LimbIsTraumaticallyAmputated(character,limbtype)
    local limbtoaffliction = {}
    limbtoaffliction[LimbType.RightLeg] = "trl_amputation"
    limbtoaffliction[LimbType.LeftLeg] = "tll_amputation"
    limbtoaffliction[LimbType.RightArm] = "tra_amputation"
    limbtoaffliction[LimbType.LeftArm] = "tla_amputation"
    if limbtoaffliction[limbtype] == nil then return false end
    return HF.HasAfflictionLimb(character,limbtoaffliction[limbtype],limbtype,0.1)
end

function NT.LimbIsSurgicallyAmputated(character,limbtype)
    local limbtoaffliction = {}
    limbtoaffliction[LimbType.RightLeg] = "srl_amputation"
    limbtoaffliction[LimbType.LeftLeg] = "sll_amputation"
    limbtoaffliction[LimbType.RightArm] = "sra_amputation"
    limbtoaffliction[LimbType.LeftArm] = "sla_amputation"
    if limbtoaffliction[limbtype] == nil then return false end
    return HF.HasAfflictionLimb(character,limbtoaffliction[limbtype],limbtype,0.1)
end