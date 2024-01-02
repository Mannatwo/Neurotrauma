Timer.Wait(function()

    local oldAnalyzerFunction = NT.ItemMethods.bloodanalyzer
    NT.ItemMethods.bloodanalyzer = function(item, usingCharacter, targetCharacter, limb) 
    
        -- only work if no cooldown
        if item.Condition < 50 then return end
        
        local containedItem = item.OwnInventory.GetItemAt(0)
        local hasNutricard = containedItem and containedItem.Prefab.Identifier.Value == "nutricard"

        if not hasNutricard then
            oldAnalyzerFunction(item,usingCharacter,targetCharacter,limb)
            return        
        end

        local success = HF.GetSkillRequirementMet(usingCharacter,"medical",30)
        local bloodlossinduced = 1
        if(not success) then bloodlossinduced = 3 end
        HF.AddAffliction(targetCharacter,"bloodloss",bloodlossinduced,usingCharacter)

        -- nutritional readout time
    
        local readoutstring = "Comprehensive metabolic panel of "..targetCharacter.Name..":\n"
        local issuestring = ""
        local nutrientstring = ""
        local nutrientsDisplayed = 0
        local charID = NTMB.GetCharacterID(targetCharacter)
        for key,val in pairs(NTMB.Nutrients) do
            if not val.hiddenOnReadout then
                local strength = HF.Round(NTMB.GetNutrientLevel(charID,key,0),(val.decimals or 1))

                -- check for abnormalities
                if val.normalRange then
                    if strength < val.normalRange[1] then
                        issuestring = issuestring.."\n! low "..HF.GetText("ntmb.nutrients."..key).." "..tostring(strength).." << "..tostring(val.normalRange[1].."-"..tostring(val.normalRange[2])).." ("..tostring(HF.Round(strength/val.normalRange[1]*100)).."% of lower normal)"
                    elseif strength > val.normalRange[2] then
                        issuestring = issuestring.."\n! high "..HF.GetText("ntmb.nutrients."..key).." "..tostring(val.normalRange[1].."-"..tostring(val.normalRange[2]).." >> "..tostring(strength)).." ("..tostring(HF.Round(strength/val.normalRange[2]*100)).."% of upper normal)"
                    end
                end
    
                -- add the nutrient to the readout
                nutrientstring = nutrientstring.."\n"..HF.GetText("ntmb.nutrients."..key)..": "..strength..val.unit
                nutrientsDisplayed = nutrientsDisplayed + 1
            end
        end
    
        -- add a message in case there is nothing to display
        if nutrientsDisplayed <= 0 then
            readoutstring = readoutstring.."\nNo nutrients detected..." 
        end

        if nutrientstring~="" then
            readoutstring = readoutstring..nutrientstring
        end

        if issuestring~="" then
            readoutstring = readoutstring.."\n\nDEFICIENCIES AND TOXICITIES:"..issuestring
        end
    
        HF.DMClient(HF.CharacterToClient(usingCharacter),readoutstring,Color(127,255,127,255))
    end

end,100)

Hook.Add("ntmb.emptypot.update", "ntmb.emptypot.update", function (effect, deltaTime, item, targets, worldPosition)
    
    -- if this pot is submerged, turn it into pot_tainted
    if item.InWater then
        local spawnIdentifier = "pot_tainted"
        if not NTConfig.Get("NTMB_taintedWater",true) then spawnIdentifier="pot_water" end

        HF.ReplaceItemIdentifier(item,spawnIdentifier)
    end

end)

Hook.Add("ntmb.emptypot", "ntmb.emptypot", function (effect, deltaTime, item, targets, worldPosition)

    -- keep track of where to put the new item
    local previousSpot = nil
    local previousInventory = item.ParentInventory
    if previousInventory then
        previousSpot = previousInventory.FindIndex(item)
    end

    -- throw out all the WATER and STUFF in the pots
    Timer.Wait(function()
        HF.SpawnItemPlusFunction("emptypot",function(params)
        end,nil,previousInventory,previousSpot,item.WorldPosition)
        HF.RemoveItem(item)
    end,1)
end)

Hook.Add("ntmb.crumplebag", "ntmb.crumplebag", function (effect, deltaTime, item, targets, worldPosition)
    Timer.Wait(function()
        HF.RemoveItem(item)
    end,1)
end)

-- butchering
NTMB.ButcheringData = {
    Crawlers={
        species={"Crawler","Legacycrawler","Crawlerlarge"},     -- which species this table applies to
        size=1,                                                 -- determines how long butchering takes, also affects process yield
        processDrops={{id="crawlermeat",chance=0.33,chancePerSkill=0.005}},
        finalDrops={{id="crawlermeat",chance=1}}
    },
    Humans={
        species={"Human"},
        size=1,
        processDrops={{id="humanmeat",chance=0.33,chancePerSkill=0.005}},
        finalDrops={{id="humanmeat",chance=1}},
        finalFunction=function(character,butcherer,skill)
            local organData = {
                {dmgAff="liverdamage",fooddrop="livertransplant_food",transplant="livertransplant_q1"},
                {dmgAff="lungdamage",fooddrop="lungtransplant_food",transplant="lungtransplant_q1"},
                {dmgAff="kidneydamage",fooddrop="kidneytransplant_food",transplant="kidneytransplant_q1"},
                {dmgAff="heartdamage",fooddrop="hearttransplant_food",transplant="hearttransplant_q1"},
                {dmgAff="cerebralhypoxia",fooddrop="braintransplant_food",transplant="braintransplant_q1"},
            }

            -- drop organs
            for data in organData do
                local dmg = HF.GetAfflictionStrength(character,data.dmgAff)
                local dropChance = 0.2+skill/100*0.8 -- 0 cooking: 20% organ drop chance, 100 cooking: 100% organ drop chance
                if HF.Chance(dropChance) then
                    local medSkill = HF.GetSkillLevel(butcherer,"medical")
                    local transplantChance =
                    HF.Minimum((100-dmg)/100,0.2,0)     -- organ condition
                    * (medSkill/100)                    -- medical skill

                    -- if organ condition is low enough (<20%), prevent transplant drops,
                    -- as there isnt enough time to put the organs into a fridge. spawn food version instead.

                    local dropID = data.fooddrop
                    local dropCondition = 100
                    if HF.Chance(transplantChance) then
                        dropID = data.transplant
                        dropCondition = (100-dmg)/2
                    end

                    local spawnPos = character.WorldPosition
                    HF.SpawnItemPlusFunction(dropID,function(params) params.item.Condition = dropCondition end,nil,nil,nil,spawnPos)
                end
                
            end

            -- drop limbs
            -- TODO
        end
    },
    Husks={
        species={"Humanhusk","Husk"},
        size=1,
        processDrops={{id="huskmeat",chance=0.33,chancePerSkill=0.005}},
        finalDrops={{id="huskmeat",chance=1}},
        finalFunction=function(character,butcherer,skill)
            local organData = {
                {dmgAff="liverdamage",fooddrop="livertransplant_food",transplant="livertransplant_q1"},
                {dmgAff="lungdamage",fooddrop="lungtransplant_food",transplant="lungtransplant_q1"},
                {dmgAff="kidneydamage",fooddrop="kidneytransplant_food",transplant="kidneytransplant_q1"},
                {dmgAff="heartdamage",fooddrop="hearttransplant_food",transplant="hearttransplant_q1"},
                {dmgAff="cerebralhypoxia",fooddrop="braintransplant_food",transplant="braintransplant_q1"},
            }

            -- drop organs
            for data in organData do
                local dmg = HF.GetAfflictionStrength(character,data.dmgAff)
                local dropChance = 0.2+skill/100*0.8 -- 0 cooking: 20% organ drop chance, 100 cooking: 100% organ drop chance
                if HF.Chance(dropChance) then
                    local medSkill = HF.GetSkillLevel(butcherer,"medical")
                    local transplantChance =
                    HF.Minimum((100-dmg)/100,0.2,0)     -- organ condition
                    * (medSkill/100)                    -- medical skill

                    -- if organ condition is low enough (<20%), prevent transplant drops,
                    -- as there isnt enough time to put the organs into a fridge. spawn food version instead.

                    local dropID = data.fooddrop
                    local dropCondition = 100
                    if HF.Chance(transplantChance) then
                        dropID = data.transplant
                        dropCondition = (100-dmg)/2
                    end

                    local spawnPos = character.WorldPosition
                    HF.SpawnItemPlusFunction(dropID,function(params) params.item.Condition = dropCondition end,nil,nil,nil,spawnPos)
                end
                
            end

            -- drop limbs
            -- TODO
        end
    },
    Mudraptors={
        species={"Mudraptor","Mudraptor_unarmored","Mudraptor_veteran","Mudraptor_passive"},size=1.5,
        processDrops={{id="mudraptormeat",chance=0.33,chancePerSkill=0.005}},
        finalDrops={{id="mudraptormeat",chance=1}}
    },
    Spinelings={
        species={"Spineling","Spineling_giant"},size=0.8,
        processDrops={{id="spinelingmeat",chance=0.33,chancePerSkill=0.005}},
        finalDrops={{id="spinelingmeat",chance=1}}
    },
    Threshers={
        species={"Bonethresher","Tigerthresher"},size=1.5,
        processDrops={{id="threshermeat",chance=0.33,chancePerSkill=0.005}},
        finalDrops={{id="threshermeat",chance=1}}
    },
    Molochs={
        species={"Moloch","Legacymoloch","Molochblack","Moloch_m","Molochblack_m"},size=4,
        processDrops={{id="molochmeat",chance=0.33,chancePerSkill=0.005}},
        finalDrops={{id="molochmeat",chance=1}}
    },
    Hammerheads={
        species={"Hammerhead","Hammerheadgold","Hammerheadmatriarch","Hammerhead_m","Hammerhead_mNamed","Hammerheadgold_m"},size=2.5,
        processDrops={{id="hammerheadmeat",chance=0.33,chancePerSkill=0.005}},
        finalDrops={{id="hammerheadmeat",chance=1},{id="hammerheadribs",chance=0.25}}
    },
    Endworms={
        species={"Endworm","Doomworm"},size=10,
        processDrops={{id="endwormmeat",chance=0.1,chancePerSkill=0.0015}},
        finalDrops={{id="endwormmeat",chance=1}}
    },
}
NTMB.CorpseButcherProgress = {
    
}
function NTMB.GetCookingSkill(character) return HF.GetSkillLevel(character,"cooking") end
Hook.Add("ntmb.butcher.progress", "ntmb.butcher.progress", function (effect, deltaTime, item, targets, worldPosition)

    local user = item.ParentInventory.Owner
    local target = targets[1]
    if not target or not user or target == user then return end

    if not NTMB.CorpseButcherProgress[target] then NTMB.CorpseButcherProgress[target] = 0 end

    for data in NTMB.ButcheringData do
        if HF.TableContains(data.species,target.SpeciesName.Value) then

            local skill = NTMB.GetCookingSkill(user)
            local dropRolls = 1 + skill/50
            NTMB.CorpseButcherProgress[target] = NTMB.CorpseButcherProgress[target] + dropRolls/data.size*10

            if data.processDrops then
                while dropRolls > 0 do
                    local chanceMult = dropRolls
                    if dropRolls>1 then chanceMult=1 end
    
                    -- butchering drops
                    for drop in data.processDrops do
                        if HF.Chance(chanceMult * ((drop.chance or 1) + skill* (drop.chancePerSkill or 0))) then
                            HF.SpawnItemAt(drop.id,target.WorldPosition)
                        end
                    end
    
                    dropRolls = dropRolls-1
                end
            end

            if NTMB.CorpseButcherProgress[target] >= 100 then
                -- finishing butchering
                if data.finalDrops then
                    for finalDrop in data.finalDrops do
                        if HF.Chance((finalDrop.chance or 1) + skill* (finalDrop.chancePerSkill or 0)) then
                            HF.SpawnItemAt(finalDrop.id,target.WorldPosition)
                        end
                    end
                end
                if data.finalFunction then
                    data.finalFunction(target,user,skill)
                end

                -- remove corpse
                for containedItem in target.Inventory.AllItemsMod do
                    containedItem.Drop(nil)
                end
                HF.RemoveCharacter(target)
            end

            break
        end
    end

end)

-- rotten organs turning into food
Timer.Wait(function() 
    NT.RotOrgan = function(item) 
        local identifier = item.Prefab.Identifier.Value
        local transplantVariants = {"liver","kidney","heart","lung","brain"}
        for var in transplantVariants do
            if identifier == var.."transplant" or identifier == var.."transplant_q1" then
                HF.ReplaceItemIdentifier(item,var.."transplant_food",false)
                return
            end
        end
        HF.RemoveItem(item)
     end
end,100)