
Hook.Add("item.applyTreatment", "NT.itemused", function(item, usingCharacter, targetCharacter, limb)
    
    if -- invalid use, dont do anything
        item == nil or
        usingCharacter == nil or
        targetCharacter == nil or
        limb == nil 
    then return end
    
    local identifier = item.Prefab.Identifier.Value

    local methodtorun = NT.ItemMethods[identifier] -- get the function associated with the identifer
    if(methodtorun~=nil) then 
         -- run said function
        methodtorun(item, usingCharacter, targetCharacter, limb)
        return
    end

    -- startswith functions
    for key,value in pairs(NT.ItemStartsWithMethods) do 
        if HF.StartsWith(identifier,key) then
            value(item, usingCharacter, targetCharacter, limb)
            return
        end
    end

end)

-- storing all of the item-specific functions in a table
NT.ItemMethods = {} -- with the identifier as the key
NT.ItemStartsWithMethods = {} -- with the start of the identifier as the key


-- misc

NT.ItemMethods.healthscanner = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = limb.type

    local containedItem = item.OwnInventory.GetItemAt(0)
    if containedItem==nil then return end
    local hasVoltage = containedItem.Condition > 0

    if hasVoltage then 
        HF.GiveItem(targetCharacter,"ntsfx_selfscan")
        containedItem.Condition = containedItem.Condition-5
        HF.AddAffliction(targetCharacter,"radiationsickness",1,usingCharacter)

        -- print readout of afflictions
        local readoutstring = "Affliction readout for "..targetCharacter.Name.." on limb "..HF.LimbTypeToString(limbtype)..":\n"
        local afflictionlist = targetCharacter.CharacterHealth.GetAllAfflictions()
        local afflictionsdisplayed = 0
        for value in afflictionlist do
            local strength = HF.Round(value.Strength)
            local prefab = value.Prefab
            local limb = targetCharacter.CharacterHealth.GetAfflictionLimb(value)
            local afflimbtype = LimbType.Torso

            if(limb~=nil) then afflimbtype=limb.type
            elseif(prefab.IndicatorLimb~=nil) then afflimbtype = prefab.IndicatorLimb end

            if (strength > prefab.ShowInHealthScannerThreshold and afflimbtype==limbtype) then
                -- add the affliction to the readout
                readoutstring = readoutstring.."\n"..value.Prefab.Name.Value..": "..strength.."%"
                afflictionsdisplayed = afflictionsdisplayed + 1
            end
        end

        -- add a message in case there is nothing to display
        if afflictionsdisplayed <= 0 then
            readoutstring = readoutstring.."\nNo afflictions! Good work!" 
        end

        Timer.Wait(function()
            HF.DMClient(HF.CharacterToClient(usingCharacter),readoutstring,Color(127,255,255,255))
        end, 2000)
    end
end
NT.HematologyDetectable = 
{"sepsis","immunity","acidosis","alkalosis","bloodloss","bloodpressure",
"afimmunosuppressant","afthiamine","afadrenaline","afstreptokinase","afantibiotics",
"afsaline","afringerssolution"}
NT.ItemMethods.bloodanalyzer = function(item, usingCharacter, targetCharacter, limb) 
    
    -- only work if no cooldown
    if item.Condition < 50 then return end
    
    local limbtype = limb.type

    local success = HF.GetSkillRequirementMet(usingCharacter,"medical",30)
    local bloodlossinduced = 1
    if(not success) then bloodlossinduced = 3 end
    HF.AddAffliction(targetCharacter,"bloodloss",bloodlossinduced,usingCharacter)

    -- spawn donor card
    local containedItem = item.OwnInventory.GetItemAt(0)
    local hasCartridge = containedItem ~= nil and containedItem.Prefab.Identifier.Value == "bloodcollector"
    if hasCartridge then 
        HF.RemoveItem(containedItem)
        local bloodtype = NT.GetBloodtype(targetCharacter)
        HF.PutItemInsideItem(item,bloodtype.."card")
    end

    -- print readout of afflictions
    local readoutstring = "Affliction readout for the blood of "..targetCharacter.Name..":\n"
    local afflictionlist = targetCharacter.CharacterHealth.GetAllAfflictions()
    local afflictionsdisplayed = 0
    for value in afflictionlist do
        local strength = HF.Round(value.Strength)
        local prefab = value.Prefab

        if (strength > 2 and HF.TableContains(NT.HematologyDetectable,prefab.Identifier.Value)) then
            -- add the affliction to the readout
            readoutstring = readoutstring.."\n"..value.Prefab.Name.Value..": "..strength.."%"
            afflictionsdisplayed = afflictionsdisplayed + 1
        end
    end

    -- add a message in case there is nothing to display
    if afflictionsdisplayed <= 0 then
        readoutstring = readoutstring.."\nNo blood pressure detected..." 
    end

    HF.DMClient(HF.CharacterToClient(usingCharacter),readoutstring,Color(127,255,255,255))
end

-- trauma shears and diving knife
NT.CuttableAfflictions = {"bandaged","dirtybandage"}
NT.TraumashearsAfflictions = {"gypsumcast"}
NT.ItemMethods.traumashears = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = limb.type

    -- don't work on stasis
    if(HF.HasAffliction(targetCharacter,"stasis",0.1)) then return end

    -- does the target have any cuttable afflictions?
    local cuttables = HF.CombineArrays(NT.CuttableAfflictions,NT.TraumashearsAfflictions)
    local canCut = false
    for val in cuttables do
        local prefab = AfflictionPrefab.Prefabs[val]
        if prefab ~= nil then
            if prefab.LimbSpecific then 
                if HF.HasAfflictionLimb(targetCharacter,val,limbtype,0.1) then canCut = true break end
            elseif HF.NormalizeLimbType(limbtype) == prefab.IndicatorLimb then
                if HF.HasAffliction(targetCharacter,val,0.1) then canCut = true break end
            end
        end
    end

    if canCut then
        if(HF.GetSkillRequirementMet(usingCharacter,"medical",10)) then
            HF.GiveItem(targetCharacter,"ntsfx_scissors")

            -- remove 8% fracture so that they dont scream again
            if(HF.HasAfflictionLimb(targetCharacter,"gypsumcast",limbtype,0.1)) then 
                HF.AddAfflictionLimb(targetCharacter,"ll_fracture",limbtype,-8,usingCharacter)
                HF.AddAfflictionLimb(targetCharacter,"rl_fracture",limbtype,-8,usingCharacter)
                HF.AddAfflictionLimb(targetCharacter,"la_fracture",limbtype,-8,usingCharacter)
                HF.AddAfflictionLimb(targetCharacter,"ra_fracture",limbtype,-8,usingCharacter)
            end

            -- remove cuttables
            for val in cuttables do
                local prefab = AfflictionPrefab.Prefabs[val]
                if prefab ~= nil then
                    if prefab.LimbSpecific then 
                        HF.SetAfflictionLimb(targetCharacter,val,limbtype,0,usingCharacter)
                    elseif HF.NormalizeLimbType(limbtype) == prefab.IndicatorLimb then
                        HF.SetAffliction(targetCharacter,val,0,usingCharacter)
                    end
                end
            end
        else
            HF.AddAfflictionLimb(targetCharacter,"bleeding",limbtype,15,usingCharacter)
            HF.AddAfflictionLimb(targetCharacter,"lacerations",limbtype,10,usingCharacter)
        end
    end
end
NT.ItemMethods.divingknife = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = limb.type

    -- don't work on stasis
    if(HF.HasAffliction(targetCharacter,"stasis",0.1)) then return end

    -- does the target have any cuttable afflictions?
    local canCut = false
    for val in NT.CuttableAfflictions do
        local prefab = AfflictionPrefab.Prefabs[val]
        if prefab ~= nil then
            if prefab.LimbSpecific then 
                if HF.HasAfflictionLimb(targetCharacter,val,limbtype,0.1) then canCut = true break end
            elseif HF.NormalizeLimbType(limbtype) == prefab.IndicatorLimb then
                if HF.HasAffliction(targetCharacter,val,0.1) then canCut = true break end
            end
        end
    end
    
    if canCut then
        if(HF.GetSkillRequirementMet(usingCharacter,"medical",30)) then
            HF.GiveItem(targetCharacter,"ntsfx_bandage")
            -- remove cuttables
            for val in NT.CuttableAfflictions do
                local prefab = AfflictionPrefab.Prefabs[val]
                if prefab ~= nil then
                    if prefab.LimbSpecific then 
                        HF.SetAfflictionLimb(targetCharacter,val,limbtype,0,usingCharacter)
                    elseif HF.NormalizeLimbType(limbtype) == prefab.IndicatorLimb then
                        HF.SetAffliction(targetCharacter,val,0,usingCharacter)
                    end
                end
            end
        else
            HF.AddAfflictionLimb(targetCharacter,"bleeding",limbtype,15,usingCharacter)
            HF.AddAfflictionLimb(targetCharacter,"lacerations",limbtype,10,usingCharacter)
        end
    end
end

NT.ItemMethods.gypsum = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = limb.type

    -- don't work on stasis
    if(HF.HasAffliction(targetCharacter,"stasis",0.1)) then return end

    if(HF.HasAfflictionLimb(targetCharacter,"bandaged",limbtype,0.1) and
        not HF.HasAfflictionLimb(targetCharacter,"gypsumcast",limbtype,0.1) and
        not HF.HasAfflictionLimb(targetCharacter,"surgeryincision",limbtype,1) and (
            limbtype~=LimbType.Waist and limbtype~=LimbType.Torso and limbtype~=LimbType.Head 
    )) then
        if(HF.GetSkillRequirementMet(usingCharacter,"medical",40)) then
            HF.SetAfflictionLimb(targetCharacter,"bandaged",limbtype,0,usingCharacter)
            HF.SetAfflictionLimb(targetCharacter,"gypsumcast",limbtype,100,usingCharacter)
            HF.AddAfflictionLimb(targetCharacter,"ll_fracture",limbtype,-20,usingCharacter)
            HF.AddAfflictionLimb(targetCharacter,"rl_fracture",limbtype,-20,usingCharacter)
            HF.AddAfflictionLimb(targetCharacter,"la_fracture",limbtype,-20,usingCharacter)
            HF.AddAfflictionLimb(targetCharacter,"ra_fracture",limbtype,-20,usingCharacter)
            HF.GiveSkillScaled(usingCharacter,"medical",200)
            HF.RemoveItem(item)
        else
            HF.RemoveItem(item)
        end
    end
end

NT.SutureAfflictions = {
    boncut1={xpgain=0,case="surgeryincision"},
    boncut2={xpgain=0,case="surgeryincision"},
    boncut3={xpgain=0,case="surgeryincision"},
    boncut4={xpgain=0,case="surgeryincision"},
    drilledbones={xpgain=0,case="surgeryincision"},

    ll_arterialcut={xpgain=1,case="retractedskin"},
    rl_arterialcut={xpgain=1,case="retractedskin"},
    la_arterialcut={xpgain=1,case="retractedskin"},
    ra_arterialcut={xpgain=1,case="retractedskin"},
    h_arterialcut={xpgain=1,case="retractedskin"},
    t_arterialcut={xpgain=2,case="retractedskin"},
    arteriesclamp={xpgain=0,case="retractedskin"},
    tamponade={xpgain=1,case="retractedskin"},
    internalbleeding={xpgain=1,case="retractedskin"},
    stroke={xpgain=2,case="retractedskin"},

    clampedbleeders={},
    surgeryincision={},
    retractedskin={}
}
NT.ItemMethods.suture = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = limb.type

    if(HF.GetSkillRequirementMet(usingCharacter,"medical",30)) then
        -- in field use
        local healeddamage = 0
        healeddamage = healeddamage + HF.Clamp(HF.GetAfflictionStrengthLimb(targetCharacter,limbtype,"lacerations",0),0,20)
        healeddamage = healeddamage + HF.Clamp(HF.GetAfflictionStrengthLimb(targetCharacter,limbtype,"bitewounds",0),0,20)
        healeddamage = healeddamage + HF.Clamp(HF.GetAfflictionStrengthLimb(targetCharacter,limbtype,"explosiondamage",0),0,20)
        healeddamage = healeddamage + HF.Clamp(HF.GetAfflictionStrengthLimb(targetCharacter,limbtype,"gunshotwound",0),0,20)
        healeddamage = healeddamage + HF.Clamp(HF.GetAfflictionStrengthLimb(targetCharacter,limbtype,"bleeding",0)/10,0,4)

        HF.AddAfflictionLimb(targetCharacter,"lacerations",limbtype,-20,usingCharacter)
        HF.AddAfflictionLimb(targetCharacter,"bitewounds",limbtype,-20,usingCharacter)
        HF.AddAfflictionLimb(targetCharacter,"explosiondamage",limbtype,-20,usingCharacter)
        HF.AddAfflictionLimb(targetCharacter,"gunshotwound",limbtype,-20,usingCharacter)
        HF.AddAfflictionLimb(targetCharacter,"bleeding",limbtype,-40,usingCharacter)
        HF.AddAfflictionLimb(targetCharacter,"suturedw",limbtype,healeddamage)

        HF.GiveSkillScaled(usingCharacter,"medical",healeddamage)

        -- terminating surgeries
        -- amputations
        if(HF.HasAfflictionLimb(targetCharacter,"boncut1",limbtype,1)) then
            local droplimb = not HF.HasAfflictionLimb(targetCharacter,"tll_amputation",limbtype,1) and not HF.HasAfflictionLimb(targetCharacter,"gangrene",limbtype,15)
            HF.SetAfflictionLimb(targetCharacter,"tll_amputation",limbtype,0,usingCharacter)
            HF.SetAfflictionLimb(targetCharacter,"sll_amputation",limbtype,100,usingCharacter)
            if (droplimb) then 
                HF.GiveItem(usingCharacter,"lleg")
                if NTSP ~= nil then HF.GiveSkill(usingCharacter,"surgery",0.5) end
             end
        end
        if(HF.HasAfflictionLimb(targetCharacter,"boncut2",limbtype,1)) then
            local droplimb = not HF.HasAfflictionLimb(targetCharacter,"trl_amputation",limbtype,1) and not HF.HasAfflictionLimb(targetCharacter,"gangrene",limbtype,15)
            HF.SetAfflictionLimb(targetCharacter,"trl_amputation",limbtype,0,usingCharacter)
            HF.SetAfflictionLimb(targetCharacter,"srl_amputation",limbtype,100,usingCharacter)
            if (droplimb) then 
                HF.GiveItem(usingCharacter,"rleg")
                if NTSP ~= nil then HF.GiveSkill(usingCharacter,"surgery",0.5) end
            end
        end
        if(HF.HasAfflictionLimb(targetCharacter,"boncut3",limbtype,1)) then
            local droplimb = not HF.HasAfflictionLimb(targetCharacter,"tla_amputation",limbtype,1) and not HF.HasAfflictionLimb(targetCharacter,"gangrene",limbtype,15)
            HF.SetAfflictionLimb(targetCharacter,"tla_amputation",limbtype,0,usingCharacter)
            HF.SetAfflictionLimb(targetCharacter,"sla_amputation",limbtype,100,usingCharacter)
            if (droplimb) then 
                HF.GiveItem(usingCharacter,"larm")
                if NTSP ~= nil then HF.GiveSkill(usingCharacter,"surgery",0.5) end
            end
        end
        if(HF.HasAfflictionLimb(targetCharacter,"boncut4",limbtype,1)) then
            local droplimb = not HF.HasAfflictionLimb(targetCharacter,"tra_amputation",limbtype,1) and not HF.HasAfflictionLimb(targetCharacter,"gangrene",limbtype,15)
            HF.SetAfflictionLimb(targetCharacter,"tra_amputation",limbtype,0,usingCharacter)
            HF.SetAfflictionLimb(targetCharacter,"sra_amputation",limbtype,100,usingCharacter)
            if (droplimb) then 
                HF.GiveItem(usingCharacter,"rarm")
                if NTSP ~= nil then HF.GiveSkill(usingCharacter,"surgery",0.5) end
            end
        end

        -- the other stuff
        local function removeAfflictionPlusGainSkill(affidentifier,skillgain)
            if HF.HasAfflictionLimb(targetCharacter,affidentifier,limbtype) then
                HF.SetAfflictionLimb(targetCharacter,affidentifier,limbtype,0,usingCharacter)

                if NTSP ~= nil then 
                    HF.GiveSkill(usingCharacter,"surgery",skillgain)
                else 
                    HF.GiveSkill(usingCharacter,"medical",skillgain/4)
                end
            end
        end
        local function removeAfflictionNonLimbSpecificPlusGainSkill(affidentifier,skillgain)
            if HF.HasAffliction(targetCharacter,affidentifier) then
                HF.SetAffliction(targetCharacter,affidentifier,0,usingCharacter)

                if NTSP ~= nil then 
                    HF.GiveSkill(usingCharacter,"surgery",skillgain)
                else 
                    HF.GiveSkill(usingCharacter,"medical",skillgain/4)
                end
            end
        end

        for key, value in pairs(NT.SutureAfflictions) do
            local prefab = AfflictionPrefab.Prefabs[key]
            if prefab ~= nil and (value.case == nil or HF.HasAfflictionLimb(targetCharacter,value.case,limbtype)) then
                if value.func ~= nil then
                    value.func(item, usingCharacter, targetCharacter, limb)
                else
                    local skillgain = value.xpgain or 0
                    if prefab.LimbSpecific then
                        removeAfflictionPlusGainSkill(key,skillgain)
                    elseif prefab.IndicatorLimb == limbtype then
                        removeAfflictionNonLimbSpecificPlusGainSkill(key,skillgain)
                    end
                end
            end
        end
        
    else
        HF.AddAfflictionLimb(targetCharacter,"internaldamage",limbtype,6)
    end
end
NT.ItemMethods.tourniquet = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = limb.type

    if(HF.GetSkillRequirementMet(usingCharacter,"medical",30) and not HF.HasAfflictionLimb(targetCharacter,"arteriesclamp",limbtype,1)) then
        
        if(
            HF.HasAfflictionLimb(targetCharacter,"ll_arterialcut",limbtype,1) or
            HF.HasAfflictionLimb(targetCharacter,"rl_arterialcut",limbtype,1) or
            HF.HasAfflictionLimb(targetCharacter,"la_arterialcut",limbtype,1) or
            HF.HasAfflictionLimb(targetCharacter,"ra_arterialcut",limbtype,1)
        ) then
            HF.SetAfflictionLimb(targetCharacter,"arteriesclamp",limbtype,100,usingCharacter)
            HF.GiveSkillScaled(usingCharacter,"medical",200)
            HF.RemoveItem(item)
        elseif(HF.HasAfflictionLimb(targetCharacter,"h_arterialcut",limbtype,1)) then
            HF.SetAffliction(targetCharacter,"oxygenlow",200,usingCharacter)
            HF.AddAffliction(targetCharacter,"cerebralhypoxia",15,usingCharacter)
            HF.RemoveItem(item)
        end
        
    else
        HF.AddAfflictionLimb(targetCharacter,"blunttrauma",limbtype,6,usingCharacter)
    end
end
NT.ItemMethods.emptybloodpack = function(item, usingCharacter, targetCharacter, limb) 
    if(targetCharacter.Bloodloss <= 31) then 
        local success = HF.GetSkillRequirementMet(usingCharacter,"medical",30)
        local bloodlossinduced = 30
        if(not success) then bloodlossinduced = 40 end

        local bloodtype = NT.GetBloodtype(targetCharacter)

        HF.AddAffliction(targetCharacter,"bloodloss",bloodlossinduced,usingCharacter)
        HF.GiveItem(usingCharacter,"bloodpack" .. bloodtype)
        HF.RemoveItem(item)
    end
end
NT.ItemMethods.propofol = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = limb.type

    local anesthesiaGained = 1
    if HF.HasTalent(usingCharacter,"ntsp_properfol") then anesthesiaGained=15 end

    if HF.GetAfflictionStrength(targetCharacter,"anesthesia",0) < 15 then
        HF.AddAffliction(targetCharacter,"anesthesia",anesthesiaGained,usingCharacter)
    end

    HF.RemoveItem(item)
    HF.GiveItem(targetCharacter,"ntsfx_syringe")
end
NT.ItemMethods.streptokinase = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = limb.type

    HF.AddAffliction(targetCharacter,"heartattack",-100,usingCharacter)
    HF.AddAffliction(targetCharacter,"hemotransfusionshock",-100,usingCharacter)
    HF.AddAffliction(targetCharacter,"afstreptokinase",50,usingCharacter)
    
    -- make stroke worse if present
    local hasStroke = HF.HasAffliction(targetCharacter,"stroke")
    if hasStroke then
        HF.AddAffliction(targetCharacter,"stroke",5,usingCharacter)
        HF.AddAffliction(targetCharacter,"cerebralhypoxia",10,usingCharacter)
    end

    HF.RemoveItem(item)
    HF.GiveItem(targetCharacter,"ntsfx_syringe")
end

NT.ItemMethods.defibrillator = function(item, usingCharacter, targetCharacter, limb)
    if item.Condition <= 0 then return end

    local containedItem = item.OwnInventory.GetItemAt(0)
    if containedItem==nil then return end
    local hasVoltage = containedItem.Condition > 0

    if hasVoltage then 
        HF.GiveItem(targetCharacter,"ntsfx_manualdefib")
        containedItem.Condition = containedItem.Condition-10
        if containedItem.Prefab.Identifier.Value ~= "fulguriumbatterycell" then containedItem.Condition = containedItem.Condition-10 end

        local successChance = (HF.GetSkillLevel(usingCharacter,"medical")/100)^2
        local arrestSuccessChance = (HF.GetSkillLevel(usingCharacter,"medical")/100)^4
        local arrestFailChance = (1-(HF.GetSkillLevel(usingCharacter,"medical")/100))^2 * 0.3

        Timer.Wait(function()
            HF.AddAffliction(targetCharacter,"stun",2,usingCharacter)
            if HF.Chance(successChance) then
                HF.SetAffliction(targetCharacter,"tachycardia",0,usingCharacter)
                HF.SetAffliction(targetCharacter,"fibrillation",0,usingCharacter)
            end
            if HF.Chance(arrestSuccessChance) then
                HF.SetAffliction(targetCharacter,"cardiacarrest",0,usingCharacter)
            elseif HF.Chance(arrestFailChance) then
                HF.SetAffliction(targetCharacter,"cardiacarrest",100,usingCharacter)
            end
        end, 2000)
    end
end
NT.ItemMethods.aed = function(item, usingCharacter, targetCharacter, limb)
    if item.Condition <= 0 then return end

    local containedItem = item.OwnInventory.GetItemAt(0)
    if containedItem==nil then return end
    local hasVoltage = containedItem.Condition > 0

    if hasVoltage then 
        local actionRequired =
            HF.HasAffliction(targetCharacter,"tachycardia",5)
            or HF.HasAffliction(targetCharacter,"fibrillation",1)
            or HF.HasAffliction(targetCharacter,"cardiacarrest") 

        if not actionRequired then
            HF.GiveItem(targetCharacter,"ntsfx_defib2")
        else
            HF.GiveItem(targetCharacter,"ntsfx_defib1")

            containedItem.Condition = containedItem.Condition-10
            if containedItem.Prefab.Identifier.Value ~= "fulguriumbatterycell" then containedItem.Condition = containedItem.Condition-10 end
    
            local arrestSuccessChance = HF.Clamp((HF.GetSkillLevel(usingCharacter,"medical")/200),0.2,0.4)

            Timer.Wait(function()
                HF.AddAffliction(targetCharacter,"stun",2,usingCharacter)
                HF.SetAffliction(targetCharacter,"tachycardia",0,usingCharacter)
                HF.SetAffliction(targetCharacter,"fibrillation",0,usingCharacter)
                if HF.Chance(arrestSuccessChance) then
                    HF.SetAffliction(targetCharacter,"cardiacarrest",0,usingCharacter)
                end
            end, 3200)
        end
    end
end

-- surgery

NT.ItemMethods.advscalpel = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = limb.type

    -- don't work on stasis
    if(HF.HasAffliction(targetCharacter,"stasis",0.1)) then return end

    if(HF.CanPerformSurgeryOn(targetCharacter) and not HF.HasAfflictionLimb(targetCharacter,"surgeryincision",limbtype,1)) then
        if(HF.GetSurgerySkillRequirementMet(usingCharacter,30)) then
            HF.AddAfflictionLimb(targetCharacter,"surgeryincision",limbtype,1+HF.GetSurgerySkill(usingCharacter)/2,usingCharacter)
            HF.SetAfflictionLimb(targetCharacter,"suturedi",limbtype,0,usingCharacter)
            HF.SetAfflictionLimb(targetCharacter,"gypsumcast",limbtype,0,usingCharacter)
            HF.SetAfflictionLimb(targetCharacter,"bandaged",limbtype,0,usingCharacter)
        else
            HF.AddAfflictionLimb(targetCharacter,"bleeding",limbtype,15,usingCharacter)
            HF.AddAfflictionLimb(targetCharacter,"lacerations",limbtype,10,usingCharacter)
        end
    end
end
NT.ItemMethods.advhemostat = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = limb.type

    -- don't work on stasis
    if(HF.HasAffliction(targetCharacter,"stasis",0.1)) then return end

    if(HF.CanPerformSurgeryOn(targetCharacter) and HF.HasAfflictionLimb(targetCharacter,"surgeryincision",limbtype,99) and not HF.HasAfflictionLimb(targetCharacter,"clampedbleeders",limbtype,1)) then
        HF.AddAfflictionLimb(targetCharacter,"clampedbleeders",limbtype,1+HF.GetSurgerySkill(usingCharacter)/2,usingCharacter)
    end
end
NT.ItemMethods.advretractors = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = limb.type

    -- don't work on stasis
    if(HF.HasAffliction(targetCharacter,"stasis",0.1)) then return end

    if(HF.CanPerformSurgeryOn(targetCharacter) and HF.HasAfflictionLimb(targetCharacter,"clampedbleeders",limbtype,99) and not HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,1)) then
        if(HF.GetSurgerySkillRequirementMet(usingCharacter,30)) then
            HF.AddAfflictionLimb(targetCharacter,"retractedskin",limbtype,1+HF.GetSurgerySkill(usingCharacter)/2,usingCharacter)
        else
            HF.AddAfflictionLimb(targetCharacter,"internaldamage",limbtype,10,usingCharacter)
        end
    end
end
NT.ItemMethods.surgicaldrill = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = limb.type

    -- don't work on stasis
    if(HF.HasAffliction(targetCharacter,"stasis",0.1)) then return end

    if(HF.CanPerformSurgeryOn(targetCharacter) and HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99) and not HF.HasAfflictionLimb(targetCharacter,"drilledbones",limbtype,1)) then
        if(HF.GetSurgerySkillRequirementMet(usingCharacter,45)) then
            HF.AddAfflictionLimb(targetCharacter,"drilledbones",limbtype,1+HF.GetSurgerySkill(usingCharacter)/2,usingCharacter)
        else
            HF.AddAfflictionLimb(targetCharacter,"bleeding",limbtype,15,usingCharacter)
            HF.AddAfflictionLimb(targetCharacter,"internaldamage",limbtype,10,usingCharacter)
        end
    end
end
NT.ItemMethods.surgerysaw = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = limb.type

    -- don't work on stasis
    if(HF.HasAffliction(targetCharacter,"stasis",0.1)) then return end

    if(HF.CanPerformSurgeryOn(targetCharacter) and HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)
        and not HF.HasAfflictionLimb(targetCharacter,"boncut1",limbtype,1)
        and not HF.HasAfflictionLimb(targetCharacter,"boncut2",limbtype,1)
        and not HF.HasAfflictionLimb(targetCharacter,"boncut3",limbtype,1)
        and not HF.HasAfflictionLimb(targetCharacter,"boncut4",limbtype,1)
    ) then
        if(HF.GetSurgerySkillRequirementMet(usingCharacter,50)) then
            if(limbtype==LimbType.LeftLeg or limbtype==LimbType.LeftThigh or limbtype==LimbType.LeftFoot) then HF.AddAfflictionLimb(targetCharacter,"boncut1",limbtype,1+HF.GetSurgerySkill(usingCharacter)/2,usingCharacter) end
            if(limbtype==LimbType.RightLeg or limbtype==LimbType.RightThigh or limbtype==LimbType.RightThigh) then HF.AddAfflictionLimb(targetCharacter,"boncut2",limbtype,1+HF.GetSurgerySkill(usingCharacter)/2,usingCharacter) end
            if(limbtype==LimbType.LeftArm or limbtype==LimbType.LeftForearm or limbtype==LimbType.LeftHand) then HF.AddAfflictionLimb(targetCharacter,"boncut3",limbtype,1+HF.GetSurgerySkill(usingCharacter)/2,usingCharacter) end
            if(limbtype==LimbType.RightArm  or limbtype==LimbType.RightForearm or limbtype==LimbType.RightHand) then HF.AddAfflictionLimb(targetCharacter,"boncut4",limbtype,1+HF.GetSurgerySkill(usingCharacter)/2,usingCharacter) end
        else
            HF.AddAfflictionLimb(targetCharacter,"bleeding",limbtype,15,usingCharacter)
            HF.AddAfflictionLimb(targetCharacter,"internaldamage",limbtype,6,usingCharacter)
            HF.AddAfflictionLimb(targetCharacter,"lacerations",limbtype,4,usingCharacter)
        end
    end
end
NT.ItemMethods.tweezers = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = limb.type

    -- don't work on stasis
    if(HF.HasAffliction(targetCharacter,"stasis",0.1)) then return end

    if(HF.CanPerformSurgeryOn(targetCharacter) and HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)) then
        if(HF.GetSurgerySkillRequirementMet(usingCharacter,30)) then
            HF.AddAfflictionLimb(targetCharacter,"lacerations",limbtype,5,usingCharacter)

            local function healAfflictionGiveSkill(identifier,healamount,skillgain) 
                local affAmount = HF.GetAfflictionStrengthLimb(targetCharacter,limbtype,"blunttrauma")
                local healedamount = math.min(affAmount,healamount)
                HF.AddAfflictionLimb(targetCharacter,identifier,limbtype,-healamount,usingCharacter)
                
                if NTSP ~= nil then 
                    HF.GiveSkillScaled(usingCharacter,"surgery",healedamount*skillgain)
                else 
                    HF.GiveSkillScaled(usingCharacter,"medical",healedamount*skillgain/2)
                end
            end

            local foreignbody = HF.GetAfflictionStrengthLimb(targetCharacter,limbtype,"foreignbody",0)
            local scrapdropchance = math.min(foreignbody,5)/5*0.05 -- 5% chance to drop scrap
            if HF.Chance(scrapdropchance) then HF.GiveItem(usingCharacter,"scrap") end

            healAfflictionGiveSkill("foreignbody",5,15)
            healAfflictionGiveSkill("internaldamage",5,3)
            healAfflictionGiveSkill("blunttrauma",5,3)
            healAfflictionGiveSkill("necrosis",5,1)
        else
            HF.AddAfflictionLimb(targetCharacter,"internaldamage",limbtype,6,usingCharacter)
        end
    end
end

NT.ItemMethods.organscalpel_liver = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = limb.type

    if(limbtype == LimbType.Torso and HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,1)) then
        local damage = HF.GetAfflictionStrength(targetCharacter,"liverdamage",0)
        local removed = HF.GetAfflictionStrength(targetCharacter,"liverremoved",0)
        if(removed <= 0) then

            if(HF.GetSurgerySkillRequirementMet(usingCharacter,40)) then
                HF.SetAffliction(targetCharacter,"liverremoved",100,usingCharacter)
                HF.SetAffliction(targetCharacter,"liverdamage",100,usingCharacter)

                HF.AddAffliction(targetCharacter,"organdamage",(100-damage)/5,usingCharacter)
                local transplantidentifier = "livertransplant_q1"
                if NTC.HasTag(usingCharacter,"organssellforfull") then transplantidentifier = "livertransplant" end
                if(damage < 90) then HF.GiveItemAtCondition(usingCharacter,transplantidentifier,100-damage) end
            else
                HF.AddAfflictionLimb(targetCharacter,"bleeding",limbtype,15,usingCharacter)
                HF.AddAfflictionLimb(targetCharacter,"organdamage",limbtype,5,usingCharacter)
                HF.AddAffliction(targetCharacter,"liverdamage",20,usingCharacter)
            end
        end
    end
end
NT.ItemMethods.organscalpel_lungs = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = limb.type

    if(limbtype == LimbType.Torso and HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,1)) then
        local damage = HF.GetAfflictionStrength(targetCharacter,"lungdamage",0)
        local removed = HF.GetAfflictionStrength(targetCharacter,"lungremoved",0)
        if(removed <= 0) then

            if(HF.GetSurgerySkillRequirementMet(usingCharacter,50)) then
                HF.SetAffliction(targetCharacter,"lungremoved",100,usingCharacter)
                HF.SetAffliction(targetCharacter,"lungdamage",100,usingCharacter)

                HF.SetAffliction(targetCharacter,"pneumothorax",0,usingCharacter)
                HF.SetAffliction(targetCharacter,"needlec",0,usingCharacter)

                HF.AddAffliction(targetCharacter,"organdamage",(100-damage)/5,usingCharacter)
                local transplantidentifier = "lungtransplant_q1"
                if NTC.HasTag(usingCharacter,"organssellforfull") then transplantidentifier = "lungtransplant" end
                if(damage < 90) then HF.GiveItemAtCondition(usingCharacter,transplantidentifier,100-damage) end
            else
                HF.AddAfflictionLimb(targetCharacter,"bleeding",limbtype,15,usingCharacter)
                HF.AddAfflictionLimb(targetCharacter,"organdamage",limbtype,5,usingCharacter)
                HF.AddAffliction(targetCharacter,"lungdamage",20,usingCharacter)
            end
        end
    end
end
NT.ItemMethods.organscalpel_heart = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = limb.type

    if(limbtype == LimbType.Torso and HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,1)) then
        local damage = HF.GetAfflictionStrength(targetCharacter,"heartdamage",0)
        local removed = HF.GetAfflictionStrength(targetCharacter,"heartremoved",0)
        if(removed <= 0) then

            if(HF.GetSurgerySkillRequirementMet(usingCharacter,60)) then
                HF.SetAffliction(targetCharacter,"heartremoved",100,usingCharacter)
                HF.SetAffliction(targetCharacter,"heartdamage",100,usingCharacter)
                
                HF.SetAffliction(targetCharacter,"tamponade",0,usingCharacter)
                
                HF.AddAffliction(targetCharacter,"organdamage",(100-damage)/5,usingCharacter)
                local transplantidentifier = "hearttransplant_q1"
                if NTC.HasTag(usingCharacter,"organssellforfull") then transplantidentifier = "hearttransplant" end
                if(damage < 90) then HF.GiveItemAtCondition(usingCharacter,transplantidentifier,100-damage) end
            else
                HF.AddAfflictionLimb(targetCharacter,"bleeding",limbtype,15,usingCharacter)
                HF.AddAfflictionLimb(targetCharacter,"organdamage",limbtype,5,usingCharacter)
                HF.AddAffliction(targetCharacter,"heartdamage",20,usingCharacter)
            end
        end
    end
end
NT.ItemMethods.organscalpel_kidneys = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = limb.type

    if(limbtype == LimbType.Torso and HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,1)) then
        local damage = HF.GetAfflictionStrength(targetCharacter,"kidneydamage",0)
        local removed = HF.GetAfflictionStrength(targetCharacter,"kidneyremoved",0)
        if(removed <= 0) then
            if(HF.GetSurgerySkillRequirementMet(usingCharacter,30)) then
                HF.SetAffliction(targetCharacter,"kidneyremoved",100,usingCharacter)
                HF.SetAffliction(targetCharacter,"kidneydamage",100,usingCharacter)
                HF.AddAffliction(targetCharacter,"organdamage",(100-damage)/5,usingCharacter)
                local transplantidentifier = "kidneytransplant_q1"
                if NTC.HasTag(usingCharacter,"organssellforfull") then transplantidentifier = "kidneytransplant" end
                if(damage < 50) then 
                    HF.GiveItemAtCondition(usingCharacter,transplantidentifier,100)
                    damage = damage+50
                end
                if(damage < 95) then
                    HF.GiveItemAtCondition(usingCharacter,transplantidentifier,100-(damage-50)*2)
                end
            else
                HF.AddAfflictionLimb(targetCharacter,"bleeding",limbtype,15,usingCharacter)
                HF.AddAfflictionLimb(targetCharacter,"organdamage",limbtype,5,usingCharacter)
                HF.AddAffliction(targetCharacter,"kidneydamage",20,usingCharacter)
            end
        end
    end
end
NT.ItemMethods.organscalpel_brain = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = limb.type

    if(limbtype == LimbType.Head and HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,1)) then
        local damage = HF.GetAfflictionStrength(targetCharacter,"cerebralhypoxia",0)
        local removed = HF.GetAfflictionStrength(targetCharacter,"brainremoved",0)
        if(removed <= 0) then

            if(HF.GetSurgerySkillRequirementMet(usingCharacter,100)) then
                HF.SetAffliction(targetCharacter,"brainremoved",100,usingCharacter)
                HF.AddAffliction(targetCharacter,"cerebralhypoxia",100,usingCharacter)
                
                if NTSP ~= nil then
                    if HF.HasAffliction(targetCharacter,"artificialbrain") then
                        HF.SetAffliction(targetCharacter,"artificialbrain",0,usingCharacter)
                        damage=100
                    end
                end
                
                if(damage < 90) then
                    local postSpawnFunction = function(item,donor,client)
                        item.Condition = 100-damage
                        if client ~= nil then
                            item.Description = client.Name
                        end
                    end

                    if SERVER then
                        -- use server spawn method
                        local prefab = ItemPrefab.GetItemPrefab("braintransplant")
                        local client = HF.CharacterToClient(targetCharacter)
                        Entity.Spawner.AddItemToSpawnQueue(prefab, usingCharacter.WorldPosition, nil, nil, function(item)
                            usingCharacter.Inventory.TryPutItem(item, nil, {InvSlotType.Any})
                            postSpawnFunction(item,targetCharacter,client)
                        end)

                        if client ~= nil then
                        client.SetClientCharacter(nil) end
                    else
                        -- use client spawn method
                        local item = Item(ItemPrefab.GetItemPrefab("braintransplant"), usingCharacter.WorldPosition)
                        usingCharacter.Inventory.TryPutItem(item, nil, {InvSlotType.Any})
                        postSpawnFunction(item,targetCharacter,nil)
                    end
                end
            else
                HF.AddAfflictionLimb(targetCharacter,"bleeding",limbtype,15,usingCharacter)
                HF.AddAffliction(targetCharacter,"cerebralhypoxia",50,usingCharacter)
            end
        end
    end
end

NT.ItemMethods.osteosynthesisimplants = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = limb.type

    if(HF.CanPerformSurgeryOn(targetCharacter) and HF.HasAfflictionLimb(targetCharacter,"drilledbones",limbtype,99)) then
        if(HF.GetSurgerySkillRequirementMet(usingCharacter,45)) then
            local function removeAfflictionPlusGainSkill(affidentifier,skillgain)
                if HF.HasAfflictionLimb(targetCharacter,affidentifier,limbtype) then
                    HF.SetAfflictionLimb(targetCharacter,affidentifier,limbtype,0,usingCharacter)

                    if NTSP ~= nil then 
                        HF.GiveSkillScaled(usingCharacter,"surgery",skillgain)
                    else 
                        HF.GiveSkillScaled(usingCharacter,"medical",skillgain/4)
                    end
                end
            end
            removeAfflictionPlusGainSkill("ll_fracture",200)
            removeAfflictionPlusGainSkill("rl_fracture",200)
            removeAfflictionPlusGainSkill("la_fracture",200)
            removeAfflictionPlusGainSkill("ra_fracture",200)
            removeAfflictionPlusGainSkill("t_fracture",200)
            removeAfflictionPlusGainSkill("h_fracture",200)
            removeAfflictionPlusGainSkill("n_fracture",200)
            removeAfflictionPlusGainSkill("boneclamp",0)
            removeAfflictionPlusGainSkill("drilledbones",0)
            HF.SetAfflictionLimb(targetCharacter,"bonegrowth",limbtype,100,usingCharacter)
            item.Condition = item.Condition-25
            if(item.Condition<=0) then HF.RemoveItem(item) end
        else
            HF.AddAfflictionLimb(targetCharacter,"bleeding",limbtype,5,usingCharacter)
            HF.AddAfflictionLimb(targetCharacter,"internaldamage",limbtype,5,usingCharacter)
        end
    end
end
NT.ItemMethods.spinalimplant = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = limb.type

    if(HF.CanPerformSurgeryOn(targetCharacter) and HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,50)) then
        if(HF.GetSurgerySkillRequirementMet(usingCharacter,45)) then
            HF.SetAfflictionLimb(targetCharacter,"t_paralysis",limbtype,0,usingCharacter)
            HF.RemoveItem(item)

            if NTSP ~= nil then 
                HF.GiveSkillScaled(usingCharacter,"surgery",400)
            else 
                HF.GiveSkillScaled(usingCharacter,"medical",100)
            end
        else
            HF.AddAfflictionLimb(targetCharacter,"bleeding",limbtype,5,usingCharacter)
            HF.AddAfflictionLimb(targetCharacter,"internaldamage",limbtype,5,usingCharacter)
        end
    end
end

NT.ItemMethods.endovascballoon = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = limb.type

    -- don't work on stasis
    if(HF.HasAffliction(targetCharacter,"stasis",0.1)) then return end

    if(limbtype == LimbType.Torso and HF.HasAfflictionLimb(targetCharacter,"surgeryincision",limbtype,1) and HF.HasAffliction(targetCharacter,"t_arterialcut",1)) then
        HF.AddAfflictionLimb(targetCharacter,"balloonedaorta",limbtype,100,usingCharacter)
        HF.SetAfflictionLimb(targetCharacter,"internalbleeding",limbtype,0,usingCharacter)

        if NTSP ~= nil then 
            HF.GiveSkillScaled(usingCharacter,"surgery",400)
        else 
            HF.GiveSkillScaled(usingCharacter,"medical",200)
        end

        if HF.Chance(NTC.GetMultiplier(usingCharacter,"balloonconsumechance")) then
            HF.RemoveItem(item)
        end
    end
end
NT.ItemMethods.medstent = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = limb.type

    -- don't work on stasis
    if(HF.HasAffliction(targetCharacter,"stasis",0.1)) then return end

    if(limbtype == LimbType.Torso and HF.HasAffliction(targetCharacter,"balloonedaorta",1)) then
        HF.SetAfflictionLimb(targetCharacter,"balloonedaorta",limbtype,0,usingCharacter)
        HF.SetAfflictionLimb(targetCharacter,"t_arterialcut",limbtype,0,usingCharacter)
    
        if NTSP ~= nil then 
            HF.GiveSkillScaled(usingCharacter,"surgery",800)
        else 
            HF.GiveSkillScaled(usingCharacter,"medical",400)
        end
    end
end
NT.ItemMethods.drainage = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = limb.type

    -- don't work on stasis
    if(HF.HasAffliction(targetCharacter,"stasis",0.1)) then return end

    if(limbtype == LimbType.Torso and HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype) and HF.HasAffliction(targetCharacter,"pneumothorax")) then
        HF.SetAfflictionLimb(targetCharacter,"pneumothorax",limbtype,0,usingCharacter)
        HF.SetAfflictionLimb(targetCharacter,"needlec",limbtype,0,usingCharacter)
    
        if HF.Chance(NTC.GetMultiplier(usingCharacter,"drainageconsumechance")) then
            HF.RemoveItem(item)
        end

        if NTSP ~= nil then 
            HF.GiveSkillScaled(usingCharacter,"surgery",400)
        else 
            HF.GiveSkillScaled(usingCharacter,"medical",200)
        end
    end
end
NT.ItemMethods.needle = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = limb.type

    -- don't work on stasis
    if(HF.HasAffliction(targetCharacter,"stasis",0.1)) then return end

    if(limbtype == LimbType.Torso) then
        if HF.GetSkillRequirementMet(usingCharacter,"medical",20) then 
            HF.SetAfflictionLimb(targetCharacter,"needlec",limbtype,100,usingCharacter)
            HF.AddAfflictionLimb(targetCharacter,"pneumothorax",limbtype,1,usingCharacter)
        
            if HF.Chance(NTC.GetMultiplier(usingCharacter,"needleconsumechance")) then
                HF.RemoveItem(item)
            end
        else 
            HF.AddAfflictionLimb(targetCharacter,"organdamage",limbtype,10,usingCharacter)
            HF.AddAfflictionLimb(targetCharacter,"bleeding",limbtype,10,usingCharacter)
        end  
    end
end

NT.ItemMethods.braintransplant = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = limb.type
    local conditionmodifier = 0
    if (not HF.GetSurgerySkillRequirementMet(usingCharacter,100)) then conditionmodifier = -40 end
    local workcondition = HF.Clamp(item.Condition+conditionmodifier,0,100)
    if(HF.HasAffliction(targetCharacter,"brainremoved",1) and limbtype == LimbType.Head) then
        HF.AddAffliction(targetCharacter,"cerebralhypoxia",-(workcondition),usingCharacter)
        HF.SetAffliction(targetCharacter,"brainremoved",0,usingCharacter)

        -- give character control to the donor
        if SERVER then
            local donorclient = item.Description
            local client = HF.ClientFromName(donorclient)
            if client ~= nil then
                client.SetClientCharacter(targetCharacter)
            end
        end

        HF.RemoveItem(item)
    end
end

-- startswith region begins

-- transplants

NT.ItemStartsWithMethods.livertransplant = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = limb.type
    local conditionmodifier = 0
    if (not HF.GetSurgerySkillRequirementMet(usingCharacter,40)) then conditionmodifier = -40 end
    local workcondition = HF.Clamp(item.Condition+conditionmodifier,0,100)
    if(HF.HasAffliction(targetCharacter,"liverremoved",1) and limbtype == LimbType.Torso and HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)) then
        HF.AddAffliction(targetCharacter,"liverdamage",-(workcondition),usingCharacter)
        HF.AddAffliction(targetCharacter,"organdamage",-(workcondition)/5,usingCharacter)
        HF.SetAffliction(targetCharacter,"liverremoved",0,usingCharacter)
        HF.RemoveItem(item)

        local rejectionchance = HF.Clamp((HF.GetAfflictionStrength(targetCharacter,"immunity",0)-10)/150*NTC.GetMultiplier(usingCharacter,"organrejectionchance"),0,1)
        if HF.Chance(rejectionchance) then
            HF.SetAffliction(targetCharacter,"liverdamage",100)
        end
    end
end
NT.ItemStartsWithMethods.hearttransplant = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = limb.type
    local conditionmodifier = 0
    if (not HF.GetSurgerySkillRequirementMet(usingCharacter,40)) then conditionmodifier = -40 end
    local workcondition = HF.Clamp(item.Condition+conditionmodifier,0,100)
    if(HF.HasAffliction(targetCharacter,"heartremoved",1) and limbtype == LimbType.Torso and HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)) then
        HF.AddAffliction(targetCharacter,"heartdamage",-(workcondition),usingCharacter)
        HF.AddAffliction(targetCharacter,"organdamage",-(workcondition)/5,usingCharacter)
        HF.SetAffliction(targetCharacter,"heartremoved",0,usingCharacter)
        HF.RemoveItem(item)

        local rejectionchance = HF.Clamp((HF.GetAfflictionStrength(targetCharacter,"immunity",0)-10)/150*NTC.GetMultiplier(usingCharacter,"organrejectionchance"),0,1)
        if HF.Chance(rejectionchance) then
            HF.SetAffliction(targetCharacter,"heartdamage",100)
        end
    end
end
NT.ItemStartsWithMethods.lungtransplant = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = limb.type
    local conditionmodifier = 0
    if (not HF.GetSurgerySkillRequirementMet(usingCharacter,40)) then conditionmodifier = -40 end
    local workcondition = HF.Clamp(item.Condition+conditionmodifier,0,100)
    if(HF.HasAffliction(targetCharacter,"lungremoved",1) and limbtype == LimbType.Torso and HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)) then
        HF.AddAffliction(targetCharacter,"lungdamage",-(workcondition),usingCharacter)
        HF.AddAffliction(targetCharacter,"organdamage",-(workcondition)/5,usingCharacter)
        HF.SetAffliction(targetCharacter,"lungremoved",0,usingCharacter)
        HF.RemoveItem(item)

        local rejectionchance = HF.Clamp((HF.GetAfflictionStrength(targetCharacter,"immunity",0)-10)/150*NTC.GetMultiplier(usingCharacter,"organrejectionchance"),0,1)
        if HF.Chance(rejectionchance) then
            HF.SetAffliction(targetCharacter,"lungdamage",100)
        end
    end
end
NT.ItemStartsWithMethods.kidneytransplant = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = limb.type
    local conditionmodifier = 0
    if (not HF.GetSurgerySkillRequirementMet(usingCharacter,40)) then conditionmodifier = -40 end
    local workcondition = HF.Clamp(item.Condition+conditionmodifier,0,100)
    if(HF.HasAffliction(targetCharacter,"kidneyremoved",1) and limbtype == LimbType.Torso and HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)) then
        
        Timer.Wait(function()
            HF.SetAffliction(targetCharacter,"kidneyremoved",0,usingCharacter)
        end, 5000)

        local rejectionchance = HF.Clamp((HF.GetAfflictionStrength(targetCharacter,"immunity",0)-10)/150*NTC.GetMultiplier(usingCharacter,"organrejectionchance"),0,1)
        if HF.Chance(rejectionchance) then 
            HF.RemoveItem(item)
            return
        end
        
        HF.AddAffliction(targetCharacter,"kidneydamage",-(workcondition)/2,usingCharacter)
        HF.AddAffliction(targetCharacter,"organdamage",-(workcondition)/10,usingCharacter)
        HF.RemoveItem(item)
    end
end

-- misc

NT.ItemStartsWithMethods.wrench = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = limb.type
    if(HF.HasAfflictionExtremity(targetCharacter,"dislocation1",limbtype,1) or 
    HF.HasAfflictionExtremity(targetCharacter,"dislocation2",limbtype,1) or
    HF.HasAfflictionExtremity(targetCharacter,"dislocation3",limbtype,1) or
    HF.HasAfflictionExtremity(targetCharacter,"dislocation4",limbtype,1)) then

        local skillrequired = 60
        if(HF.HasAffliction(targetCharacter,"analgesia",0.5)) then skillrequired = skillrequired-30 end

        if(HF.GetSkillRequirementMet(usingCharacter,"medical",skillrequired)) then 
            HF.SetAfflictionLimb(targetCharacter,"dislocation1",limbtype,0,usingCharacter)
            HF.SetAfflictionLimb(targetCharacter,"dislocation2",limbtype,0,usingCharacter)
            HF.SetAfflictionLimb(targetCharacter,"dislocation3",limbtype,0,usingCharacter)
            HF.SetAfflictionLimb(targetCharacter,"dislocation4",limbtype,0,usingCharacter)

            HF.GiveSkillScaled(usingCharacter,"medical",75)
        else
            if(limbtype == LimbType.LeftArm or limbtype == LimbType.LeftForearm or limbtype == LimbType.LeftHand) then HF.AddAfflictionLimb(targetCharacter,"la_fracture",LimbType.LeftArm,1,usingCharacter) 
            elseif(limbtype == LimbType.RightArm or limbtype == LimbType.RightForearm or limbtype == LimbType.RightHand) then HF.AddAfflictionLimb(targetCharacter,"ra_fracture",LimbType.RightArm,1,usingCharacter) 
            elseif(limbtype == LimbType.LeftLeg or limbtype == LimbType.LeftThigh or limbtype == LimbType.LeftFoot) then HF.AddAfflictionLimb(targetCharacter,"ll_fracture",LimbType.LeftLeg,1,usingCharacter) 
            elseif(limbtype == LimbType.RightLeg or limbtype == LimbType.RightThigh or limbtype == LimbType.RightFoot) then HF.AddAfflictionLimb(targetCharacter,"rl_fracture",LimbType.RightLeg,1,usingCharacter) end
        end

        if(not HF.HasAffliction(targetCharacter,"analgesia",0.5)) then
            HF.AddAffliction(targetCharacter,"severepain",5,usingCharacter) end
    end
end
NT.ItemStartsWithMethods.bloodpack = function(item, usingCharacter, targetCharacter, limb) 
    local identifier = item.Prefab.Identifier.Value
    local packtype = string.sub(identifier, string.len("bloodpack")+1)
    
    local packhasantibodyA = string.find(packtype, "a")
    local packhasantibodyB = string.find(packtype, "b")
    local packhasantibodyRh = string.find(packtype, "plus")

    local targettype = NT.GetBloodtype(targetCharacter)

    local targethasantibodyA = string.find(targettype, "a")
    local targethasantibodyB = string.find(targettype, "b")
    local targethasantibodyRh = string.find(targettype, "plus")

    local compatible = 
    (targethasantibodyRh or not packhasantibodyRh) and
    (targethasantibodyA or not packhasantibodyA) and
    (targethasantibodyB or not packhasantibodyB)

    if compatible then 
        HF.AddAffliction(targetCharacter,"bloodloss",-30,usingCharacter)
        HF.AddAffliction(targetCharacter,"bloodpressure",30,usingCharacter)
    else
        HF.AddAffliction(targetCharacter,"bloodloss",-20,usingCharacter)
        HF.AddAffliction(targetCharacter,"bloodpressure",30,usingCharacter)
        local immunity = HF.GetAfflictionStrength(targetCharacter,"immunity",100)
        HF.AddAffliction(targetCharacter,"hemotransfusionshock",math.max(immunity-6,0),usingCharacter)
    end

    HF.RemoveItem(item)
    HF.GiveItem(usingCharacter,"emptybloodpack")
    HF.GiveItem(targetCharacter,"ntsfx_syringe")
end

