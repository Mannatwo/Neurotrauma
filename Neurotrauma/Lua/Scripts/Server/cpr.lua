Hook.Add("human.CPRSuccess", "NT.CPRSuccess", function(animcontroller)
    if animcontroller==nil or animcontroller.Character==nil or animcontroller.Character.SelectedCharacter==nil then return end
    local character = animcontroller.Character.SelectedCharacter
    
    HF.AddAffliction(character,"cpr_buff",2)
    HF.AddAffliction(character,"cpr_fracturebuff",2) -- prevent fractures during CPR (fuck baro physics)
end)

Hook.Add("human.CPRFailed", "NT.CPRFailed", function(animcontroller)
    if animcontroller==nil or animcontroller.Character==nil or animcontroller.Character.SelectedCharacter==nil then return end
    local character = animcontroller.Character.SelectedCharacter

    HF.AddAffliction(character,"cpr_fracturebuff",2) -- prevent fractures during CPR (fuck baro physics)
    HF.AddAfflictionLimb(character,"blunttrauma",LimbType.Torso,0.3)
    if(HF.Chance(NT.Config.fractureChance * NT.Config.CPRFractureChance * 0.2 / HF.GetSkillLevel(animcontroller.Character,"medical"))) then
        HF.AddAffliction(character,"t_fracture",1)
    end
end)