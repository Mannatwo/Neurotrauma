
local limbtypes = {
    LimbType.Torso,
    LimbType.Head,
    LimbType.LeftArm,
    LimbType.RightArm,
    LimbType.LeftLeg,
    LimbType.RightLeg,
}
local function HasLungs(c) return not HF.HasAffliction(c,"lungremoved") end

Hook.Add("changeFallDamage", "NT.falldamage", function(impactDamage, character, impactPos, velocity)

    -- dont bother with creatures
    if not character.IsHuman then return end

    -- dont apply fall damage in water
    if character.InWater then return 0 end

    local velocityMagnitude = HF.Magnitude(velocity)
    velocityMagnitude = velocityMagnitude^1.5

    -- apply fall damage to all limbs based on fall direction
    local mainlimbPos = character.AnimController.MainLimb.WorldPosition

    local limbDotResults = {}
    local minDotRes = 1000

    for limb in character.AnimController.Limbs do
        for type in limbtypes do
            if limb.type == type then

                -- fetch the direction of each limb relative to the torso
                local limbPosition = limb.WorldPosition
                local posDif = limbPosition-mainlimbPos
                posDif.X = posDif.X/100
                posDif.Y = posDif.Y/100
                local posDifMagnitude = HF.Magnitude(posDif)
                if posDifMagnitude > 1 then 
                    posDif.Normalize()
                end

                local normalizedVelocity = Vector2(velocity.X,velocity.Y)
                normalizedVelocity.Normalize()

                -- compare those directions to the direction we're moving
                -- this will later be used to hurt the limbs facing impact more than the others
                local limbDot = Vector2.Dot(posDif,normalizedVelocity)
                limbDotResults[type] = limbDot
                if minDotRes > limbDot then minDotRes = limbDot end
                break
            end
        end
    end

    -- shift all weights out of the negatives
    -- increase the weight of all limbs if speed is high
    -- the effect of this is that, at higher speeds, all limbs take damage instead of mainly the ones facing the impact site
    for type,dotResult in pairs(limbDotResults) do
        limbDotResults[type] = dotResult-minDotRes + math.max(0,(velocityMagnitude-30)/10)
    end

    -- count weight so we're able to distribute the damage fractionally
    local weightsum = 0
    for dotResult in limbDotResults do
        weightsum = weightsum + dotResult
    end

    for type,dotResult in pairs(limbDotResults) do
        local relativeWeight = dotResult/weightsum

        local damageInflictedToThisLimb = relativeWeight * math.max(0,velocityMagnitude-10)^1.5 * NT.Config.falldamage * 0.5
        NT.CauseFallDamage(character,type,damageInflictedToThisLimb)
    end

    -- make the normal damage not run
    return 0 
end)
NT.CauseFallDamage = function(character,limbtype,strength)

    HF.AddAfflictionLimb(character,"blunttrauma",limbtype,strength)

    local fractureImmune = false

    local injuryChanceMultiplier = NT.Config.falldamageSeriousInjuryChance
    

    -- torso
    if not fractureImmune and strength >= 1 and limbtype==LimbType.Torso then
        if HF.Chance((strength-15)/100*NTC.GetMultiplier(character,"anyfracturechance")*NT.Config.fractureChance*injuryChanceMultiplier) then
            NT.BreakLimb(character,limbtype)
            if HasLungs(character) and strength >= 5 and HF.Chance(strength/70*NTC.GetMultiplier(character,"pneumothoraxchance")*NT.Config.pneumothoraxChance) then
                HF.AddAffliction(character,"pneumothorax",5)
            end
        end
    end

    -- head
    if not fractureImmune and strength >= 1 and limbtype==LimbType.Head then
        if strength >= 15 and HF.Chance(math.min(strength/100,0.7)) then
            HF.AddAfflictionResisted(character,"concussion",10) end
        if strength >= 15 and HF.Chance(math.min((strength-15)/100,0.7)*NTC.GetMultiplier(character,"anyfracturechance")*NT.Config.fractureChance*injuryChanceMultiplier) then
            NT.BreakLimb(character,limbtype) end
        if strength >= 15 and HF.Chance(math.min((strength-15)/100,0.7)*NTC.GetMultiplier(character,"anyfracturechance")*NT.Config.fractureChance*injuryChanceMultiplier) then
            HF.AddAffliction(character,"n_fracture",5) end
        if strength >= 5 and HF.Chance(0.7) then
            HF.AddAffliction(character,"cerebralhypoxia",strength*HF.RandomRange(0.1,0.4)) end
    end

    -- extremities
    if not fractureImmune and strength >= 1 and HF.LimbIsExtremity(limbtype) then
        if HF.Chance((strength-15)/100*NTC.GetMultiplier(character,"anyfracturechance")*NT.Config.fractureChance*injuryChanceMultiplier) then
            NT.BreakLimb(character,limbtype)
            if HF.Chance((strength-2)/60) then
                -- this is here to simulate open fractures
                NT.ArteryCutLimb(character,limbtype)
            end
        end
        if HF.Chance(HF.Clamp((strength-5)/120,0,0.5)*NTC.GetMultiplier(character,"dislocationchance")*NT.Config.dislocationChance*injuryChanceMultiplier) and not NT.LimbIsAmputated(character,limbtype) then
            NT.DislocateLimb(character,limbtype) end
    end

end