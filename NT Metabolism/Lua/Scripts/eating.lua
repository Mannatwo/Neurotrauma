
NTMB.eatables = {
    proteinbar={
        nutrients={
            protein=300
        },
        tags={"processed"},
        xmlConditionLoss=10,
        biteSize=1,
        weight=40
    },
    friedblob={
        nutrients={
            fat=100
        },
        tags={"fat"},
        eatTime=5,
        biteSize=0.5,
        weight=150
    },
    carrot={
        nutrients={
            water=63,
            sodium=50,
            potassium=230,
            carbohydrates=7,
            protein=0.7,
            magnesium=7,
            vitaminc=7
        },
        tags={"vegetable"},
        eatTime=5,
        biteSize=0.5,
        weight=72,
        digestionSpeed=2
    },
    potato={
        nutrients={
            water=284,
            sodium=22,
            potassium=1553,
            carbohydrates=64,
            protein=7,
            magnesium=73,
            vitaminc=121
        },
        tags={"vegetable"},
        eatTime=5,
        biteSize=0.5,
        weight=360,
        digestionSpeed=1
    },
    tomato={
        nutrients={
            water=95,
            carbohydrates=5,
            fat=0.25,
            sodium=22,
            potassium=300,
            protein=1,
            magnesium=73,
            vitaminc=17,
            vitamink=10
        },
        tags={"vegetable","vegetable"},
        eatTime=5,
        biteSize=0.5,
        weight=100,
        digestionSpeed=2
    },
    lettuce={
        nutrients={
            water=340,
            carbohydrates=10,
            fat=0.5,
            sodium=100,
            potassium=700,
            protein=5,
            magnesium=38,
            vitaminc=55
        },
        tags={"vegetable"},
        eatTime=10,
        biteSize=0.2,
        weight=360,
        digestionSpeed=3
    },
    pickle={
        nutrients={
            water=95,
            carbohydrates=1.5,
            fat=0.1,
            sodium=785,
            potassium=15,
            protein=0.2,
            vitaminc=1
        },
        tags={"vegetable"},
        eatTime=5,
        biteSize=0.5,
        weight=65,
        digestionSpeed=2
    },
    onion={
        nutrients={
            water=95,
            carbohydrates=14,
            fat=0.2,
            sodium=6,
            potassium=219,
            protein=1.7,
            magnesium=10.5
        },
        tags={"vegetable"},
        eatTime=5,
        biteSize=0.5,
        weight=150,
        digestionSpeed=2
    },

    salad={
        eatTime=5,
        biteSize=0.5,
        tags={"vegetable","prepared"},
        leftovers="plate"
    },
    
    flour={
        nutrients={
            carbohydrates=760,
            fat=10,
            sodium=20,
            potassium=1070,
            protein=100,
            magnesium=175
        },
        tags={"grain"},
        eatTime=100,
        biteSize=0.05,
        weight=1000
    },
    salt={
        nutrients={
            sodium=38758,
            potassium=8
        },
        tags={"mineral","spice"},
        eatTime=120,
        biteSize=0.01,
        weight=100
    },
    breaddough={
        nutrients={
            carbohydrates=234,
            fat=23.4,
            sodium=1836,
            potassium=353,
            protein=32
        },
        tags={"grain"},
        eatTime=20,
        biteSize=0.1,
        weight=506
    },
    bread={
        eatTime=5,
        biteSize=0.5,
        tags={"grain","prepared"},
    },
    burger={
        eatTime=5,
        biteSize=0.5,
        tags={"grain","prepared","meat"},
        digestionSpeed=0.8,
    },
    veggieburger={
        eatTime=5,
        biteSize=0.5,
        tags={"grain","prepared"},
        digestionSpeed=1.5,
    },
    pizza={
        eatTime=10,
        biteSize=0.125,
        tags={"grain","prepared"}
    },
    rawpizza={
        eatTime=10,
        biteSize=0.125,
        tags={"grain","prepared"}
    },
    pizzaslice={
        eatTime=2,
        biteSize=1,
        tags={"grain","prepared"}
    },
    ntrib={
        eatTime=5,
        biteSize=0.5,
        tags={"grain","meat","prepared"}
    },
    processedbread={
        eatTime=5,
        biteSize=0.2,
        tags={"grain","prepared"}
    },
    fries={
        eatTime=5,
        biteSize=0.5,
        tags={"vegetable","prepared"}
    },

    -- organs
    livertransplant={
        disableEating=true,
        tags={"meat","humanmeat"},
        nutrients={
            water=1125,
            carbohydrates=37.5,
            fat=55.5,
            protein=315,
            sodium=1305,
            vitaminc=420
        },
        weight=1500,
        digestionSpeed=0.5,
        biteSize=0.2,
        transformToFood="livertransplant_food", -- if used in food, turn into this item instead
        transformResetsCondition=true
    },
    lungtransplant={
        disableEating=true,
        tags={"meat","humanmeat"},
        nutrients={
            water=750,
            fat=31,
            protein=166,
            sodium=810,
            potassium=1510,
            vitaminc=88,
            vitaminb12=846
        },
        weight=1000,
        digestionSpeed=0.5,
        biteSize=0.2,
        transformToFood="lungtransplant_food", -- if used in food, turn into this item instead
        transformResetsCondition=true
    },
    kidneytransplant={
        disableEating=true,
        tags={"meat","humanmeat"},
        nutrients={
            water=97,
            fat=7.57,
            protein=38.35,
            sodium=282,
            potassium=534,
            vitaminb12=1100
        },
        weight=130,
        digestionSpeed=0.5,
        biteSize=1,
        transformToFood="kidneytransplant_food", -- if used in food, turn into this item instead
        transformResetsCondition=true
    },
    hearttransplant={
        disableEating=true,
        tags={"meat","humanmeat"},
        nutrients={
            water=225,
            fat=38,
            protein=204,
            sodium=525,
            potassium=3090,
            vitaminb12=2400,
            vitaminb1=501
        },
        weight=300,
        digestionSpeed=0.5,
        biteSize=0.5,
        transformToFood="hearttransplant_food", -- if used in food, turn into this item instead
        transformResetsCondition=true
    },
    braintransplant={
        disableEating=true,
        tags={"meat","humanmeat"},
        nutrients={
            water=1125,
            fat=142,
            protein=182,
            sodium=1365,
            magnesium=180,
            potassium=2925,
            vitaminb12=888,
            vitaminc=350,
        },
        weight=1500,
        digestionSpeed=0.5,
        biteSize=0.2,
        transformToFood="braintransplant_food", -- if used in food, turn into this item instead
        transformResetsCondition=true
    },

    friedliver={
        tags={"meat","humanmeat"},
        nutrients={
            water=800,
            carbohydrates=37.5,
            fat=65.5,
            protein=315,
            sodium=1305,
            vitaminc=420
        },
        weight=1500,
        digestionSpeed=0.4,
        eatTime=10,
        biteSize=0.125,
    },
    deepfriedliver={
        tags={"meat","humanmeat"},
        nutrients={
            water=400,
            carbohydrates=37.5,
            fat=75.5,
            protein=315,
            sodium=1305,
            vitaminc=420
        },
        weight=1500,
        digestionSpeed=0.3,
        eatTime=10,
        biteSize=0.125,
    },

    -- Meats
    hammerheadribs={
        disableEating=false,
        tags={"meat"},
        nutrients={
            water=7500,
            fat=3000,
            protein=1400,
            sodium=6700,
            potassium=21800,
            magnesium=1225,
            vitaminb1=316,
            vitaminb12=8200
        },
        weight=10000,
        digestionSpeed=0.5,
        eatTime=100,
        biteSize=0.01,
    },
    humanmeat={
        disableEating=false,
        tags={"meat","humanmeat"},
        nutrients={
            water=375,
            fat=150,
            protein=70,
            sodium=335,
            potassium=1090,
            magnesium=61,
            vitaminb1=15,
            vitaminb12=410
        },
        weight=50,
        digestionSpeed=0.5,
        eatTime=10,
        biteSize=0.2,
    },
    crawlermeat={
        disableEating=false,
        tags={"meat"},
        nutrients={
            water=375,
            fat=150,
            protein=70,
            sodium=335,
            potassium=1090,
            magnesium=61,
            vitaminb1=15,
            vitaminb12=410
        },
        weight=50,
        digestionSpeed=0.5,
        eatTime=10,
        biteSize=0.2,
    },
    huskmeat={
        disableEating=false,
        tags={"meat","humanmeat"},
        nutrients={
            water=375,
            fat=150,
            protein=70,
            sodium=335,
            potassium=1090,
            magnesium=61,
            vitaminb1=15,
            vitaminb12=410
        },
        weight=50,
        digestionSpeed=0.5,
        eatTime=10,
        biteSize=0.2,
    },
    mudraptormeat={
        disableEating=false,
        tags={"meat"},
        nutrients={
            water=375,
            fat=150,
            protein=70,
            sodium=335,
            potassium=1090,
            magnesium=61,
            vitaminb1=15,
            vitaminb12=410
        },
        weight=50,
        digestionSpeed=0.5,
        eatTime=10,
        biteSize=0.2,
    },
    threshermeat={
        disableEating=false,
        tags={"meat"},
        nutrients={
            water=375,
            fat=150,
            protein=70,
            sodium=335,
            potassium=1090,
            magnesium=61,
            vitaminb1=15,
            vitaminb12=410
        },
        weight=50,
        digestionSpeed=0.5,
        eatTime=10,
        biteSize=0.2,
    },
    spinelingmeat={
        disableEating=false,
        tags={"meat"},
        nutrients={
            water=375,
            fat=150,
            protein=70,
            sodium=335,
            potassium=1090,
            magnesium=61,
            vitaminb1=15,
            vitaminb12=410
        },
        weight=50,
        digestionSpeed=0.5,
        eatTime=10,
        biteSize=0.2,
    },
    hammerheadmeat={
        disableEating=false,
        tags={"meat"},
        nutrients={
            water=375,
            fat=150,
            protein=70,
            sodium=335,
            potassium=1090,
            magnesium=61,
            vitaminb1=15,
            vitaminb12=410
        },
        weight=50,
        digestionSpeed=0.5,
        eatTime=10,
        biteSize=0.2,
    },
    molochmeat={
        disableEating=false,
        tags={"meat"},
        nutrients={
            water=375,
            fat=150,
            protein=70,
            sodium=335,
            potassium=1090,
            magnesium=61,
            vitaminb1=15,
            vitaminb12=410
        },
        weight=50,
        digestionSpeed=0.5,
        eatTime=10,
        biteSize=0.2,
    },
    endwormmeat={
        disableEating=false,
        tags={"meat"},
        nutrients={
            water=7500,
            fat=3000,
            protein=1400,
            sodium=6700,
            potassium=21800,
            magnesium=1225,
            vitaminb1=316,
            vitaminb12=8200
        },
        weight=10000,
        digestionSpeed=0.5,
        eatTime=100,
        biteSize=0.01,
    },
}

NTMB.eatables.livertransplant_q1    = NTMB.eatables.livertransplant
NTMB.eatables.kidneytransplant_q1   = NTMB.eatables.kidneytransplant
NTMB.eatables.lungtransplant_q1     = NTMB.eatables.lungtransplant
NTMB.eatables.hearttransplant_q1    = NTMB.eatables.hearttransplant

local transplantVariants = {"liver","kidney","heart","lung","brain"}
for t in transplantVariants do
    local newIndex = t.."transplant_food"
    NTMB.eatables[newIndex] = HF.Clone(NTMB.eatables[t.."transplant"])
    NTMB.eatables[newIndex].transformToFood = nil
    NTMB.eatables[newIndex].transformResetsCondition = nil
end


-- eating items by health interface
Hook.Add("item.applyTreatment", "NTMB.healthinterfaceeating", function(item, usingCharacter, targetCharacter, limb)
    
    if -- invalid use, dont do anything
        item == nil or
        usingCharacter == nil or
        targetCharacter == nil or
        limb == nil 
    then return end

    -- force feeding
    if (not NTConfig.Get("NTMB_forceFeeding",true)) and usingCharacter ~= targetCharacter then return end
    
    local identifier = item.Prefab.Identifier.Value

    local eatableData = NTMB.ItemToEatableData(item) or NTMB.eatables[identifier]

    if not eatableData or eatableData.disableEating then 
        return
    end

    -- trying to eat if full
    local stuffed = HF.GetAfflictionStrength(targetCharacter,"sym_stuffed",0)
    if stuffed > 10 and HF.Chance((stuffed-10)/90) then
        -- oopsie poopsie someone tried to eat a hamburga while full!!!!!!! :(
        HF.SetAffliction(targetCharacter,"nausea_instant",1)
        return
    end

    if eatableData.biteSize == nil then
        eatableData.biteSize=1
    end

    NTMB.EatItem(item,eatableData,NTMB.GetCharacterID(targetCharacter),eatableData.biteSize,eatableData.biteSize)

end)

-- eating items by right click
Hook.Add("item.secondaryUse", "NTMB.manualeating", function(item,character)
    
    local eatableData = NTMB.ItemToEatableData(item) or NTMB.eatables[item.Prefab.Identifier.Value]

    if eatableData then

        if eatableData.disableEating then return end

        -- trying to eat if full
        if HF.Chance(1/60) then
            local stuffed = HF.GetAfflictionStrength(character,"sym_stuffed",0)
            if stuffed > 10 and HF.Chance((stuffed-10)/90) then
                -- oopsie poopsie someone tried to eat a hamburga while full!!!!!!! :(
                HF.SetAffliction(character,"nausea_instant",1)
                return
            end
        end

        local eatFraction = 0

        if eatableData.eatTime == nil and eatableData.xmlConditionLoss == nil then
            eatableData.eatTime=5
        end

        if eatableData.eatTime then
            eatFraction = 1/60/eatableData.eatTime
        end

        local conditionloss = eatFraction
        eatFraction = eatFraction+1/60*(eatableData.xmlConditionLoss or 0)/100

        NTMB.EatItem(item,eatableData,NTMB.GetCharacterID(character),eatFraction,conditionloss)
    end

end)

function NTMB.EatItem(item,eatableData,charID,fraction,conditionloss)
    if item.Removed  or not eatableData then return end
    fraction = math.min(fraction,item.Condition/100)
    eatableData.nutrients = eatableData.nutrients or {}

    local consumedContents = {fractionLeft=fraction,eatableData=HF.Clone(eatableData)}

    -- add contents to stomach
    local metabolismData = NTMB.GetMetabolismData(charID)

    local added = false
    for contents in metabolismData.stomach.contents do
        -- compare new contents to already present contents
        -- stack if matching contents found
        local matches = #contents.eatableData.nutrients == #consumedContents.eatableData.nutrients
        if matches then
            for nutrient,amount in pairs(consumedContents.eatableData.nutrients) do
                if (not contents.eatableData.nutrients[nutrient]) or contents.eatableData.nutrients[nutrient] ~= amount then
                    matches = false
                    break
                end
            end
        end
        if matches then
            -- found matching preexisting data, merge
            contents.fractionLeft = contents.fractionLeft + consumedContents.fractionLeft
            added=true
            break
        end
    end

    -- couldnt find matching data, add new one
    if not added then
        table.insert(metabolismData.stomach.contents,consumedContents)
    end

    
    

    item.Condition = item.Condition - conditionloss*100
    if item.Condition <= 0 then
        Timer.Wait(function() 
            
            -- if the dish had a plate, replace it with the plate
            -- we're not eating plates
            if eatableData.leftovers then
                local identifier = eatableData.leftovers
                local prefab = ItemPrefab.GetItemPrefab(identifier)
                local targetinventory = item.ParentInventory
                local targetslot = 0
                if targetinventory ~= nil then targetslot = targetinventory.FindIndex(item) end

                local function SpawnFunc(leftoverItem,targetinventory)
                    Timer.Wait(function()
                        if targetinventory~=nil then
                            targetinventory.TryPutItem(leftoverItem, targetslot,true,true,nil)
                        end
                    end,1)
                end

                if SERVER then
                    Entity.Spawner.AddItemToSpawnQueue(prefab, item.WorldPosition, nil, nil, function(leftoverItem)
                        HF.RemoveItem(item)
                        SpawnFunc(leftoverItem,targetinventory)
                    end)
                else
                    -- use client spawn method
                    local leftoverItem = Item(prefab, item.WorldPosition)
                    SpawnFunc(leftoverItem,targetinventory)
                end
            end
            
            HF.RemoveItem(item)
        end
        ,1)
    end

    NTMB.RefreshStuffedness(charID,false)
end

function NTMB.RefreshStuffedness(charID,updateHunger)
    local weightInStomach = 0
    local charDat = NTMB.GetMetabolismData(charID)
    local character = NTMB.GetCharacterFromID(charID)
    for contents in charDat.stomach.contents do
        weightInStomach = weightInStomach + contents.fractionLeft*(contents.eatableData.weight or 0)
    end

    -- stuffed starts at 0.5kg in the stomach, ramps up until 1.5kg in stomach
    local stuffedness = HF.Clamp(((weightInStomach-500)/1000)*100,0,100)
    HF.SetAffliction(character,"sym_stuffed",stuffedness)

    if updateHunger then
        local hungerChange = NTMB.Deltatime*(0.1 - weightInStomach/500)*NTConfig.Get("NTMB_hungerSpeed",1) -- 50g in the stomach is enough to counteract hunger gain
        if hungerChange < 0 then hungerChange = hungerChange * 4 end -- if theres enough in your stomach, hunger recovery is quicker
        if stuffedness > 0 then
            hungerChange = -1000
        end
        charDat.stomach.hunger = HF.Clamp(charDat.stomach.hunger+hungerChange,-50,100)
        HF.SetAffliction(character,"sym_hunger",HF.Clamp(charDat.stomach.hunger,0,100))
    end
end

-- vomiting
Hook.Add("NT.vomitblood", "NTMB.vomitblood", function(...)
    local character = table.pack(...)[3]
    NTMB.Vomit(character)
end)
Hook.Add("NT.vomit", "NTMB.vomit", function(...)
    local character = table.pack(...)[3]
    NTMB.Vomit(character)
end)
function NTMB.Vomit(character)
    local charID = NTMB.GetCharacterID(character)
    local charDat = NTMB.GetMetabolismData(charID)

    -- losing stomach acid
    local lostAcid = charDat.stomach.acid/2
    charDat.stomach.acid = math.max(1,charDat.stomach.acid-charDat.stomach.acid/2)

    -- losing water
    NTMB.AddNutrientLevel(charID,"water",NTMB.Nutrients.water.absorptionMultiplier * lostAcid * 20)

    -- losing stomach contents
    -- 200g
    local newContents = {}
    for contents in charDat.stomach.contents do
        local lostFraction = math.min(contents.fractionLeft,
            400 / #charDat.stomach.contents / contents.eatableData.weight)

        contents.fractionLeft = contents.fractionLeft-lostFraction
        if contents.fractionLeft > 0 then
            table.insert(newContents,contents)
        end
    end
    charDat.stomach.contents=newContents
    NTMB.RefreshStuffedness(charID,true)
end