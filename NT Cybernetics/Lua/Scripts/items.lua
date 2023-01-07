
Hook.Add("item.applyTreatment", "NTCyb.itemused", function(item, usingCharacter, targetCharacter, limb)
    local identifier = item.Prefab.Identifier.Value

    local methodtorun = NTCyb.ItemMethods[identifier] -- get the function associated with the identifer
    if(methodtorun~=nil) then 
         -- run said function
        methodtorun(item, usingCharacter, targetCharacter, limb)
        return
    end

    -- startswith functions
    for key,value in pairs(NTCyb.ItemStartsWithMethods) do 
        if HF.StartsWith(identifier,key) then
            value(item, usingCharacter, targetCharacter, limb)
            return
        end
    end
    --Stringcontains fuctions
    for key,value in pairs(NTCyb.ItemStringcontainsMethods) do 
        if HF.StartsWith(identifier,key) then
            value(item, usingCharacter, targetCharacter, limb)
            return
        end
    end

end)

-- storing all of the item-specific functions in a table
NTCyb.ItemMethods = {} -- with the identifier as the key
NTCyb.ItemStartsWithMethods = {} -- with the start of the identifier as the key
NTCyb.ItemStringcontainsMethods= {}

NTCyb.ItemMethods.fpgacircuit = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = HF.NormalizeLimbType(limb.type)

    if not NTCyb.HF.LimbIsCyber(targetCharacter,limbtype) then return end
    if HF.GetAfflictionStrengthLimb(targetCharacter,limbtype,"ntc_damagedelectronics",0) < 0.1 then return end

    if(HF.GetSkillRequirementMet(usingCharacter,"electrical",40)) then
        HF.AddAfflictionLimb(targetCharacter,"ntc_damagedelectronics",limbtype,-50)
    else
        HF.AddAfflictionLimb(targetCharacter,"ntc_damagedelectronics",limbtype,-20)
    end

    HF.GiveItem(targetCharacter,"ntcsfx_screwdriver")
    HF.RemoveItem(item)
end

NTCyb.ItemMethods.steel = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = HF.NormalizeLimbType(limb.type)

    if not NTCyb.HF.LimbIsCyber(targetCharacter,limbtype) then return end
    if HF.GetAfflictionStrengthLimb(targetCharacter,limbtype,"ntc_materialloss",0) < 0.1 then return end

    if(HF.GetSkillRequirementMet(usingCharacter,"mechanical",60)) then
        HF.AddAfflictionLimb(targetCharacter,"ntc_materialloss",limbtype,-50)
    else
        HF.AddAfflictionLimb(targetCharacter,"ntc_materialloss",limbtype,-20)
    end

    if math.random() < 0.5 then 
        HF.GiveItem(targetCharacter,"ntcsfx_screwdriver") else 
        HF.GiveItem(targetCharacter,"ntcsfx_welding") end
    HF.RemoveItem(item)
end

NTCyb.ItemMethods.weldingtool = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = HF.NormalizeLimbType(limb.type)

    if not NTCyb.HF.LimbIsCyber(targetCharacter,limbtype) then return end
    if HF.GetAfflictionStrengthLimb(targetCharacter,limbtype,"ntc_bentmetal",0) < 0.1 then return end

    local containedItem = item.OwnInventory.GetItemAt(0)
    if containedItem==nil then return end
    local hasFuel = containedItem.HasTag("weldingtoolfuel") and containedItem.Condition > 0
    if not hasFuel then return end

    Timer.Wait(function()
        NTCyb.ConvertDamageTypes(targetCharacter,limbtype)
        if(HF.GetSkillRequirementMet(usingCharacter,"mechanical",50)) then
            HF.AddAfflictionLimb(targetCharacter,"ntc_bentmetal",limbtype,-20)
        else
            HF.AddAfflictionLimb(targetCharacter,"ntc_bentmetal",limbtype,-5)
        end
    end,1)
    

    HF.GiveItem(targetCharacter,"ntcsfx_welding")
    containedItem.Condition = containedItem.Condition-2
end

NTCyb.ItemMethods.cyberarm = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = HF.NormalizeLimbType(limb.type)

    if NTCyb.HF.LimbIsCyber(targetCharacter,limbtype) then return end
    if not NT.LimbIsSurgicallyAmputated(targetCharacter,limbtype) then return end
    if limbtype ~= LimbType.LeftArm and limbtype~=LimbType.RightArm then return end

    if(HF.GetSkillRequirementMet(usingCharacter,"mechanical",70)) then
        NTCyb.CyberifyLimb(targetCharacter,limbtype)
        HF.RemoveItem(item)
    else
        HF.AddAfflictionLimb(targetCharacter,"internaldamage",limbtype,20)
    end
end

NTCyb.ItemMethods.cyberleg = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = HF.NormalizeLimbType(limb.type)

    if NTCyb.HF.LimbIsCyber(targetCharacter,limbtype) then return end
    if not NT.LimbIsSurgicallyAmputated(targetCharacter,limbtype) then return end
    if limbtype ~= LimbType.LeftLeg and limbtype~=LimbType.RightLeg then return end

    if(HF.GetSkillRequirementMet(usingCharacter,"mechanical",70)) then
        NTCyb.CyberifyLimb(targetCharacter,limbtype)
        HF.RemoveItem(item)
    else
        HF.AddAfflictionLimb(targetCharacter,"internaldamage",limbtype,20)
    end
end

NTCyb.ItemStringcontainsMethods.crowbar = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = HF.NormalizeLimbType(limb.type)

    if not NTCyb.HF.LimbIsCyber(targetCharacter,limbtype) then return end

    -- removing the limb yourself
    if usingCharacter == targetCharacter then
        NTCyb.UncyberifyLimb(targetCharacter,limbtype)
        NT.TraumamputateLimbMinusItem(targetCharacter,limbtype)
        HF.GiveItem(targetCharacter,"ntcsfx_cyberdeath")
        HF.AddAfflictionLimb(targetCharacter,"internaldamage",limbtype,HF.RandomRange(10,20))
        return
    end

    -- getting your limb removed by someone else
    if(HF.GetSkillRequirementMet(usingCharacter,"weapons",50)) then
        HF.AddAfflictionLimb(targetCharacter,"ntc_materialloss",limbtype,20)
    else
        HF.AddAfflictionLimb(targetCharacter,"ntc_materialloss",limbtype,10)
    end

    HF.GiveItem(targetCharacter,"ntcsfx_cyberblunt")
end

-- startswith region begins

NTCyb.ItemStringcontainsMethods.screwdriver = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = limb.type

    if not NTCyb.HF.LimbIsCyber(targetCharacter,limbtype) then return end
    if HF.GetAfflictionStrengthLimb(targetCharacter,limbtype,"ntc_loosescrews",0) < 0.1 then return end

    if(HF.GetSkillRequirementMet(usingCharacter,"mechanical",40)) then
        HF.AddAfflictionLimb(targetCharacter,"ntc_loosescrews",limbtype,-20)
    else
        HF.AddAfflictionLimb(targetCharacter,"ntc_loosescrews",limbtype,-5)
    end

    HF.GiveItem(targetCharacter,"ntcsfx_screwdriver")
end

