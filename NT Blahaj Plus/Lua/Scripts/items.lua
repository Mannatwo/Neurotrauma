
Timer.Wait(function() 

    NT.ItemMethods.blahajplus = function(item, usingCharacter, targetCharacter, limb)
        if item.Condition <= 0 then return end
        item.Condition = 0
        HF.GiveItem(targetCharacter,"ntsfx_squeak")
        HF.AddAffliction(targetCharacter,"psychosis",-10,usingCharacter)
    end

    NT.ItemMethods.blahajplusplus = function(item, usingCharacter, targetCharacter, limb)
        if item.Condition <= 0 then return end
        item.Condition = 0
        HF.GiveItem(targetCharacter,"ntsfx_squeak")
        HF.AddAffliction(targetCharacter,"psychosis",-50,usingCharacter)
    end

end,1)
--[[
Hook.Add("surgerybookgiveskill", "givesurgerybookskill", function (effect, deltaTime, item, targets, worldPosition)
    local character = targets[3]
    if NT.Config.NTBPenableSwedicalSkill then
        HF.GiveSkill(character,"surgery",8)
        HF.GiveSkill(character,"medical",2)
    else
        HF.GiveSkill(character,"medical",8)
    end
end)
]]