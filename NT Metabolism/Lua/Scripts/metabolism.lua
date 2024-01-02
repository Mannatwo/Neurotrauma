
NTMB.UpdateCooldown = 0
NTMB.UpdateInterval = 60 * 10
NTMB.Deltatime = NTMB.UpdateInterval/60 -- Time in seconds that transpires between updates
NTMB.MetabolismData = {}

Hook.Add("think", "NTMB.update", function()
    if HF.GameIsPaused() then return end

    NTMB.UpdateExertion()

    NTMB.UpdateCooldown = NTMB.UpdateCooldown-1
    if (NTMB.UpdateCooldown <= 0) then
        NTMB.UpdateCooldown = NTMB.UpdateInterval
        NTMB.Update()
    end
end)

-- gets run once every ten seconds
function NTMB.Update()

    local updateHumans = {}
    local amountHumans = 0

    -- fetchcharacters to update
    for key, character in pairs(Character.CharacterList) do
        if not character.IsDead then
            if character.IsHuman then
                table.insert(updateHumans, character)
                amountHumans = amountHumans + 1
            end
        end
    end

    -- we spread the characters out over the duration of an update so that the load isnt done all at once
    for key, value in pairs(updateHumans) do
        -- make sure theyre still alive and human
        if (value ~= nil and not value.Removed and value.IsHuman and not value.IsDead) then
            Timer.Wait(function ()
                if (value ~= nil and not value.Removed and value.IsHuman and not value.IsDead) then
                    NTMB.UpdateMetabolism(value) end
            end, ((key + 1) / amountHumans) * NTMB.Deltatime * 1000)
        end
    end

    
end


local limbtypes={
    LimbType.LeftArm,
    LimbType.RightArm,
    LimbType.LeftLeg,
    LimbType.RightLeg,
    LimbType.Torso,
    LimbType.Head}

function NTMB.UpdateMetabolism(character)
    if not NTMB.ShouldHaveMetabolism(character) then return end

    local charID = NTMB.GetCharacterID(character)
    local charDat = NTMB.GetMetabolismData(charID)

    local metabolismSpeed = NTConfig.Get("NTMB_metabolismSpeed",1)

    local exertion = (charDat.exertion or 0)*NTConfig.Get("NTMB_exertionImpact",1) -- determines drain rate. walking: 0.5*V.X, running: 1*V.X, ladders: 3*V.Y, swimming: 2*V.Mag
    charDat.exertion=0

    -- energy upkeep
    local energyCost = NTMB.Deltatime*metabolismSpeed

    local weightTable = {}
    local weightSum = 0
    for key,val in pairs(NTMB.Nutrients) do
        if val.type=="energy" then
            weightTable[key] = val.useWeight
            weightSum = weightSum+val.useWeight
        end
    end
    local prevIterationEnergyCost = energyCost
    while energyCost > 0.01 do
        local iterationStartEnergyCost = energyCost
        for key,val in pairs(weightTable) do
            local redeemedEnergy = math.min(NTMB.GetNutrientLevel(charID,key,0), iterationStartEnergyCost * val / weightSum)
            energyCost = energyCost - redeemedEnergy
            NTMB.AddNutrientLevel(charID,key,-redeemedEnergy)
        end

        -- prevent infinite loop in case that we run out of energy
        if prevIterationEnergyCost == energyCost then
            break
        end

        prevIterationEnergyCost = energyCost
    end

    -- penalize if starving
    if energyCost > 0 then
        HF.AddAffliction(character,"organdamage",energyCost)
    end

    
    -- stomach acid regeneration
    -- depends on sodium level
    charDat.stomach.acid = HF.Clamp(charDat.stomach.acid
        +0.5*NTMB.Deltatime*HF.Clamp((NTMB.GetNutrientLevel(charID,"sodium",140)/140)^3,0,2)
    ,0,100)
    
    -- digestion
    local newContents = {}
    for contents in charDat.stomach.contents do
        local digestedFraction = math.min(contents.fractionLeft,
            charDat.stomach.acid/100 * 5 * (contents.eatableData.digestionSpeed or 1) * NTConfig.Get("NTMB_digestionSpeed",1) * NTMB.Deltatime
            / #charDat.stomach.contents / (contents.eatableData.weight or 1))

        for nutrient,amount in pairs(contents.eatableData.nutrients) do
            if NTMB.Nutrients[nutrient] then
                NTMB.AddNutrientLevel(charID,nutrient,
                    amount
                    *digestedFraction
                    *(NTMB.Nutrients[nutrient].absorptionMultiplier or 1)
                )
            end
        end

        contents.fractionLeft = contents.fractionLeft-digestedFraction
        if contents.fractionLeft > 0 then
            table.insert(newContents,contents)
        end
    end
    charDat.stomach.contents=newContents
    NTMB.RefreshStuffedness(charID,true)

    -- water, minerals and vitamins
    for key,val in pairs(NTMB.Nutrients) do
        if val.type~="energy" then
            if val.normalRange and (val.idleDrainRate or val.exertDrainRate) then
                local prevValue = NTMB.GetNutrientLevel(charID,key,(val.normalRange[1]+val.normalRange[2])/2)
                
                -- normalization
                local normalizationFactor = 1
                if prevValue < val.normalRange[1] then
                    normalizationFactor = HF.Lerp(1,prevValue/val.normalRange[1],math.min(1,NTConfig.Get("NTMB_rateNormalization",1)))
                elseif prevValue > val.normalRange[2] then
                    local timesNormal = prevValue/val.normalRange[2]
                    normalizationFactor = HF.Lerp(1,timesNormal,NTConfig.Get("NTMB_rateNormalization",1))
                end

                local drainrate =
                    ((val.idleDrainRate or 0)
                    + (val.exertDrainRate or 0) * exertion)
                    * normalizationFactor

                local newValue = math.max(prevValue-drainrate*NTMB.Deltatime*metabolismSpeed,0)
                NTMB.SetNutrientLevel(charID,key,newValue)

                -- run nutrient function
                -- responsible for causing symptoms or starving (from anything other than lacking energy)
                if val.func then
                    val.func(charID,character,newValue,key)
                end
            end
        else
            -- run nutrient function
            -- responsible for causing symptoms or starving (from anything other than lacking energy)
            if val.func then
                val.func(charID,character,NTMB.GetNutrientLevel(charID,key,0),key)
            end
        end

        
    end

end

function NTMB.ShouldHaveMetabolism(character)
    if character.IsDead then return false end
    if CLIENT or HF.CharacterToClient(character) then return true end
    if NTConfig.Get("NTMB_crewAIMetabolsim") and character.TeamID == CharacterTeamType.Team1 then return true end
    return false
end

function NTMB.GetNutrientLevel(charID,nutrient,default)
    local charDat = NTMB.GetMetabolismData(charID)
    if not charDat or not charDat.nutrients or not charDat.nutrients[nutrient] or not charDat.nutrients[nutrient].amount then return default end
    return charDat.nutrients[nutrient].amount
end

function NTMB.SetNutrientLevel(charID,nutrient,value)
    local charDat = NTMB.GetMetabolismData(charID)
    if not charDat or not charDat.nutrients or not charDat.nutrients[nutrient] or not charDat.nutrients[nutrient].amount then return end
    charDat.nutrients[nutrient].amount = value
end

function NTMB.AddNutrientLevel(charID,nutrient,value)
    local charDat = NTMB.GetMetabolismData(charID)
    if not charDat or not charDat.nutrients or not charDat.nutrients[nutrient] or not charDat.nutrients[nutrient].amount then return end
    charDat.nutrients[nutrient].amount = charDat.nutrients[nutrient].amount + value
end

-- loops through all nutrients and tallies up those marked as energy
function NTMB.GetEnergyLevel(charID)
    local res = 0
    for key,val in pairs(NTMB.Nutrients) do
        if val.type=="energy" then
            res = res + NTMB.GetNutrientLevel(charID,key,0)
        end
    end
end

function NTMB.GetMetabolismData(charID)
    if NTMB.MetabolismData[charID] then return NTMB.MetabolismData[charID] end
    if not NTMB.LoadMetabolismData(charID) then
        NTMB.ResetMetabolismData(charID)
    end
    return NTMB.MetabolismData[charID]
end

function NTMB.ResetMetabolismData(charID)
    local newDat = {nutrients={},ID=charID,stomach={acid=100,hunger=-50,contents={}}}

    for key,entry in pairs(NTMB.Nutrients) do
        newDat.nutrients[key] = {
            amount=(entry.normalRange[1]+entry.normalRange[2])/2
        }
    end

    NTMB.MetabolismData[charID] = newDat
end

function NTMB.Debug()
    for key,entry in pairs(NTMB.MetabolismData) do
        print(key," ", NTMB.GetCharacterFromID(key).Name)
        if #entry.stomach.contents > 0 then
            print("stomach:")
            for entry2 in entry.stomach.contents do
                print("fraction left: ",entry2.fractionLeft)
                for nutrient,amount in pairs(entry2.eatableData.nutrients) do
                    print(nutrient,": ",amount)
                end
            end
        end
    end
end
function NTMB.ClearMetabolismData(charID)
    NTMB.CI.Set("NTMB_MetabolismData_"..tostring(charID),nil)
    NTMB.MetabolismData[charID] = nil
end

Hook.Add("stop", "NTMB.Stop", function ()
    NTMB.SaveMetabolismData()
end)

Hook.Add("missionsEnded", "NTMB.RoundEnd", function ()
    NTMB.SaveMetabolismData()
    NTMB.CorpseButcherProgress = {}
end)

function NTMB.SaveMetabolismData()
    for key,val in pairs(NTMB.MetabolismData) do
        local thisDat = val
        thisDat.ID = key
        local data = json.serialize(thisDat)
        NTMB.CI.Set("NTMB_MetabolismData_"..tostring(key),data)
    end
end

function NTMB.LoadMetabolismData(charID)
    local data = NTMB.CI.Get("NTMB_MetabolismData_"..tostring(charID),"")
    if (not data) or data == "" then return false end
    data = json.parse(data)
    if data and data.ID then
        NTMB.MetabolismData[charID] = data
        return true
    else
        return false
    end
end



LuaUserData.RegisterType("Barotrauma.HumanWalkParams")
LuaUserData.RegisterType("Barotrauma.HumanRunParams")
LuaUserData.RegisterType("Barotrauma.HumanSwimSlowParams")
LuaUserData.RegisterType("Barotrauma.HumanSwimFastParams")
LuaUserData.RegisterType("Barotrauma.HumanCrouchParams")
local animEnum = LuaUserData.CreateEnumTable("Barotrauma.AnimController+Animation")
local exertionDeltaTime = 1/60
-- checks for if anyone is walking, running, crouching, climbing etc.
-- used to determine how many nutrients should be used up
-- mostly water and sodium (sweat)
function NTMB.UpdateExertion()
    -- fetchcharacters to update
    for character in Character.CharacterList do
        if not character.IsDead then
            if character.IsHuman then
                -- determine exertion this tick

                local velocity = HF.GetVelocity(character)
                local velocityMagnitude = HF.Magnitude(velocity)
                local charDat = NTMB.GetMetabolismData(NTMB.GetCharacterID(character))

                -- walking: 0.5*V.X, running: 1*V.X, ladders: 3*V.Y, swimming: 2*V.Mag
                local running = false
                if velocityMagnitude > 0.1 then

                    local newExertion = 0
                    local animController = character.AnimController
                    local anim = animController.Anim
                    

                    -- moving
                    if velocity.Y > 0 then
                        -- going up
                        if anim == animEnum.Climbing then
                            -- this character is climbing a ladder (upwards)
                            newExertion = newExertion+(velocity.Y/2)*3 * exertionDeltaTime
                        end
                    end
                    
                    if math.abs(velocity.X) > 0.1 then
                        -- moving horizontally
                        if animController.CurrentAnimationParams == animController.WalkParams then
                            -- walking
                            newExertion = newExertion+math.abs(velocity.X/1.7)*0.5 * exertionDeltaTime

                        elseif animController.CurrentAnimationParams == animController.RunParams then
                            -- running
                            newExertion = newExertion+math.abs(velocity.X/4.8)*1 * exertionDeltaTime
                            charDat.runTime = math.min((charDat.runTime or 0)+1*exertionDeltaTime,60)
                            running = true
                        end
                    end
                    

                    if animController.CurrentAnimationParams == animController.SwimSlowParams or animController.CurrentAnimationParams == animController.SwimFastParams then
                        -- swimming
                        newExertion = newExertion+velocityMagnitude/1.1*2 * exertionDeltaTime

                    end

                    charDat.exertion = (charDat.exertion or 0)+newExertion
                end

                if not running then
                    charDat.runTime = math.max(0,(charDat.runTime or 0)-0.5*exertionDeltaTime)
                end
                if charDat.runTime > 20 then
                    NTC.SetSymptomTrue(character,"sym_sweating",2)
                end
            end
        end
    end
end