
local limbtypes={
    LimbType.LeftArm,
    LimbType.RightArm,
    LimbType.LeftLeg,
    LimbType.RightLeg,
    LimbType.Torso,
    LimbType.Head}

local blahajRegeneratedAfflictions={
    {"bleeding",1,true},
    {"blunttrauma",1,true},
    {"lacerations",1,true},
    {"gunshotwound",1,true},
    {"bitewounds",1,true},
    {"explosiondamage",1,true},
    {"internaldamage",1,true},
    {"foreignbody",0.5,true},
    {"coma",0.5,false},
    {"concussion",0.1,false},
    {"bloodloss",1,false},
}

local function checkInventoryForItemsRecursive(inventory,identifier,prev)
    local res = prev or 0

    if inventory==nil then return res end

    -- check inventorys items
    for item in inventory.AllItems do
        local thisIdentifier = item.Prefab.Identifier.Value

        -- if this is a relevant item, increment the count
        if thisIdentifier == identifier then
            res = res + 1
        end

        -- check the inventory of this item for the relevant items
        local thisInventory = item.OwnInventory
        res = checkInventoryForItemsRecursive(thisInventory,identifier,res)
    end
    return res
end

-- multipliers that are used in humanupdate are set here
function NTBP.PreUpdateHuman(character)

    -- blahaj power

    local blahajPower = 0
    if HF.HasTalent(character,"ntbp_blahajpower") then
        local powerPoints = 0

        -- tally up blahajes and haj items
        powerPoints = 2 * checkInventoryForItemsRecursive(character.Inventory,"blahaj") + powerPoints
        powerPoints = 4 * checkInventoryForItemsRecursive(character.Inventory,"blahajplus") + powerPoints
        powerPoints = 10 * checkInventoryForItemsRecursive(character.Inventory,"blahajplusplus") + powerPoints
        powerPoints = 10 * checkInventoryForItemsRecursive(character.Inventory,"blahajarmor") + powerPoints
        powerPoints = 10 * checkInventoryForItemsRecursive(character.Inventory,"blahajrifle") + powerPoints
        powerPoints = 8 * checkInventoryForItemsRecursive(character.Inventory,"sharkmask") + powerPoints
        powerPoints = 8 * checkInventoryForItemsRecursive(character.Inventory,"sharkscooter") + powerPoints
    
        if HF.HasTalent(character,"ntbp_freehandouts") then
            -- tally up posters
            powerPoints = 1.5 * checkInventoryForItemsRecursive(character.Inventory,"bpposter_blahaj1") + powerPoints
            powerPoints = 1.5 * checkInventoryForItemsRecursive(character.Inventory,"bpposter_blahaj2") + powerPoints
            powerPoints = 1.5 * checkInventoryForItemsRecursive(character.Inventory,"bpposter_blahaj3") + powerPoints
            powerPoints = 1.5 * checkInventoryForItemsRecursive(character.Inventory,"bpposter_trans") + powerPoints
            powerPoints = 2.5 * checkInventoryForItemsRecursive(character.Inventory,"bpposter_superblahaj") + powerPoints
        end

        blahajPower = HF.Clamp(powerPoints,0,100)
    end
    HF.ApplyAfflictionChange(character,"blahajpower",blahajPower, HF.GetAfflictionStrength(character,"blahajpower"),0,100)

    -- blahaj armor

    local blahajArmorProteccPoints = 0
    local blahajArmorSpeedPoints = 0
    local blahajArmorRegenPoints = 0
    local blahajArmorCrisisPoints = 0
    local armor = HF.GetOuterWear(character)
    if armor ~= nil and armor.Prefab.Identifier.Value == "blahajarmor" then
        
        local armorInventory = armor.OwnInventory
        
        -- tally up contaiend items
        local armorHajes = checkInventoryForItemsRecursive(armorInventory,"blahaj")
        local armorHajesPlus = checkInventoryForItemsRecursive(armorInventory,"blahajplus")
        local armorHajesPlusPlus = checkInventoryForItemsRecursive(armorInventory,"blahajplusplus")
        local armorPostersHaj1 = checkInventoryForItemsRecursive(armorInventory,"bpposter_blahaj1")
        local armorPostersHaj2 = checkInventoryForItemsRecursive(armorInventory,"bpposter_blahaj2")
        local armorPostersHaj3 = checkInventoryForItemsRecursive(armorInventory,"bpposter_blahaj3")
        local armorPostersTrans = checkInventoryForItemsRecursive(armorInventory,"bpposter_trans")
        local armorPostersSuperHaj = checkInventoryForItemsRecursive(armorInventory,"bpposter_superblahaj")
    
        blahajArmorProteccPoints =
            armorHajes * 5 +
            armorHajesPlus * 10 +
            armorHajesPlusPlus * 25 + 
            armorPostersHaj1 * 5 +
            armorPostersSuperHaj * 5 * 0.8

        blahajArmorSpeedPoints =
            2 * armorPostersHaj2 +
            armorPostersSuperHaj * 2 * 0.8


        blahajArmorRegenPoints =
            4 * armorPostersHaj3 +
            armorPostersSuperHaj * 4 * 0.8

        blahajArmorRegenPoints =
            2 * armorPostersTrans +
            armorPostersSuperHaj * 2 * 0.8
    end

    -- poster effects

    local inRangePosters = {
        bpposter_blahaj1=0,
        bpposter_blahaj2=0,
        bpposter_blahaj3=0,
        bpposter_trans=0,
        bpposter_superblahaj=0
    }
    for poster in NTBP.Posters do
        if poster ~= nil and not poster.Removed then
            local distance = HF.Distance(character.WorldPosition,poster.WorldPosition)
            if distance < NTBP.PostersRange then

                -- check if this poster is attached
                local holdableComponent = poster.GetComponent(Components.Holdable)
                if holdableComponent~= nil and holdableComponent.Attached then
                    if inRangePosters[poster.Prefab.Identifier.Value] == nil then
                        inRangePosters[poster.Prefab.Identifier.Value] = 1
                    else
                        inRangePosters[poster.Prefab.Identifier.Value] = inRangePosters[poster.Prefab.Identifier.Value] + 1
                    end
                end
            end
        end
    end

    -- blahaj buffs

    local prevattacc = HF.GetAfflictionStrength(character,"blahajattac")
    local attacc = HF.BoolToNum(HF.HasTalent(character,"ntbp_heattacc"),blahajPower)
    local prevprotecc = HF.GetAfflictionStrength(character,"blahajprotecc")
    local protecc =
        (((HF.BoolToNum(HF.HasTalent(character,"ntbp_heprotecc"),blahajPower)
        +blahajArmorProteccPoints
        +HF.Clamp(inRangePosters.bpposter_blahaj1+inRangePosters.bpposter_superblahaj,0,3)*15*NTBP.PostersPotency
    )/200)^(0.5))*100
    local prevcrisis = HF.GetAfflictionStrength(character,"blahajcrisis")
    local crisis =
        HF.BoolToNum(HF.HasTalent(character,"ntbp_identitycrisis"),blahajPower)
        +blahajArmorRegenPoints
        +HF.Clamp(inRangePosters.bpposter_trans+inRangePosters.bpposter_superblahaj,0,3)*15*NTBP.PostersPotency
    local prevspeed = HF.GetAfflictionStrength(character,"blahajspeed")
    local speed = blahajPower/2
        + blahajArmorSpeedPoints/2
        + HF.Clamp(inRangePosters.bpposter_blahaj2+inRangePosters.bpposter_superblahaj,0,3)*NTBP.PostersPotency*15
    local prevregen = HF.GetAfflictionStrength(character,"blahajregen")
    local regen =
        blahajArmorRegenPoints/2
        + HF.Clamp(inRangePosters.bpposter_blahaj3+inRangePosters.bpposter_superblahaj,0,3)*NTBP.PostersPotency*10
    
    HF.ApplyAfflictionChange(character,"blahajattac",attacc,prevattacc,0,100)
    HF.ApplyAfflictionChange(character,"blahajprotecc",protecc,prevprotecc,0,100)
    HF.ApplyAfflictionChange(character,"blahajcrisis",crisis,prevcrisis,0,100)
    HF.ApplyAfflictionChange(character,"blahajspeed",speed,prevspeed,0,100)
    HF.ApplyAfflictionChange(character,"blahajregen",regen,prevregen,0,100)

    -- blahaj shield

    local targetBlahajShield = HF.BoolToNum(HF.HasTalent(character,"ntbp_gotbacc"),blahajPower)
    local blahajShield = HF.GetAfflictionStrength(character,"blahajgotbacc")
    local prevBlahajShield = blahajShield

    if blahajShield<targetBlahajShield then
        blahajShield = HF.Clamp(blahajShield
            + NT.Deltatime * 0.1
        ,0,targetBlahajShield)
    end

    HF.ApplyAfflictionChange(character,"blahajgotbacc",blahajShield,prevBlahajShield,0,100)

    -- blahaj regeneration

    if regen > 0 then
        local regenMultiplier = -regen/100 * NT.Deltatime
        for data in blahajRegeneratedAfflictions do
            if data[3] then
                for limbtype in limbtypes do
                    HF.AddAfflictionLimb(character,data[1],limbtype,data[2]*regenMultiplier)
                end
            else
                HF.AddAffliction(character,data[1],data[2]*regenMultiplier)
            end
        end
    end

    

end

-- multipliers that are used outside of humanupdate are set here
function NTBP.PostUpdateHuman(character)

    local blahajPower = HF.GetAfflictionStrength(character,"blahajpower")

    -- advanced cuddles

    if HF.HasTalent(character,"ntbp_advancedcuddles") then

        local multiplier = 1 - HF.Clamp(blahajPower/100,0,1)*0.7

        NTC.SetMultiplier(character,"foreignbodymultiplier",multiplier)
        NTC.SetMultiplier(character,"dislocationchance",    multiplier)
        NTC.SetMultiplier(character,"anyfracturechance",    multiplier)
        NTC.SetMultiplier(character,"pneumothoraxchance",   multiplier)
        NTC.SetMultiplier(character,"tamponadechance",      multiplier)
        NTC.SetMultiplier(character,"traumamputatechance",  multiplier)
    end

end

function NTBP.TickUpdateHuman(character)
    if character.InWater then

        local headwear = HF.GetHeadWear(character)

        if HF.HasTalent(character,"ntbp_ramventilation") or 
        (
            headwear ~= nil and
            HF.ItemHasTag(headwear,"ramventilating")
        ) then

            local speed = character.CurrentSpeed
            local healedO2 = speed/60*12
            HF.AddAffliction(character,"oxygenlow",-healedO2)
        end
    end
end