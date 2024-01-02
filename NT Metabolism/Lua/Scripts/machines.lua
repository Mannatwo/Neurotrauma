
NTMB.Stoves = {}
NTMB.Ovens = {}
NTMB.Fryers = {}
NTMB.ItemData = {}

Hook.Add("roundStart", "NTMB.RoundStart.machines", function()
    NTMB.FetchMachines()
end)

function NTMB.FetchMachines() 

    NTMB.Stoves = {}
    NTMB.Ovens = {}
    NTMB.Fryers = {}
    NTMB.ItemData = {}

    -- fetch machine items
    for item in Item.ItemList do
        if item.Prefab.Identifier.Value == "stove" then
            table.insert(NTMB.Stoves,item)
        elseif item.Prefab.Identifier.Value == "oven" then
            table.insert(NTMB.Ovens,item)
        elseif item.Prefab.Identifier.Value == "fryer" then
            table.insert(NTMB.Fryers,item)
        end
    end
end
NTMB.FetchMachines()


NTMB.MachineUpdateCooldown = 0
NTMB.MachineUpdateInterval = 60 * 1
NTMB.MachineDeltatime = NTMB.MachineUpdateInterval/60 -- Time in seconds that transpires between updates
NTMB.MetabolismData = {}

Hook.Add("think", "NTMB.update.machines", function()
    if HF.GameIsPaused() then return end

    NTMB.MachineUpdateCooldown = NTMB.MachineUpdateCooldown-1
    if (NTMB.MachineUpdateCooldown <= 0) then
        NTMB.MachineUpdateCooldown = NTMB.MachineUpdateInterval
        NTMB.UpdateMachines() -- for updating machines
        NTMB.UpdateMachineItems() -- for updating temperature of ingredients in machines, or ones that just left them
    end
end)

function NTMB.FilterIngredients(ingredients,tag,excludeItems)
    local res = {}
    excludeItems = excludeItems or {}
    for item in ingredients do
        local eatableData = NTMB.ItemToEatableData(item)
        if
            (not HF.TableContains(excludeItems,item)) and
            (HF.ItemHasTag(item,tag) or 
            (   NTMB.Ingredients[eatableData.sourceIdentifier] 
                and NTMB.Ingredients[eatableData.sourceIdentifier].tags
                and HF.TableContains(NTMB.Ingredients[eatableData.sourceIdentifier].tags,tag)))
        then
            table.insert(res,item)
        end
    end
    return res
end

function NTMB.UpdateMachines()
    -- remove invalid entries
    local toRemove = {}
    for stove in NTMB.Stoves do if stove.Removed then table.insert(toRemove,stove) end end
    for item in toRemove do NTMB.Stoves[item] = nil end

    toRemove = {}
    for oven in NTMB.Ovens do if oven.Removed then table.insert(toRemove,oven) end end
    for item in toRemove do NTMB.Ovens[item] = nil end

    toRemove = {}
    for fryer in NTMB.Fryers do if fryer.Removed then table.insert(toRemove,fryer) end end
    for item in toRemove do NTMB.Fryers[item] = nil end


    for oven in NTMB.Ovens do

        local lightComponent = oven.GetComponent(Components.Powered)
        if lightComponent.IsActive and lightComponent.Voltage > 0.5 then
            NTMB.UpdateHeaterMachine(oven,"oven")
        end
    end

    for stove in NTMB.Stoves do

        local lightComponent = stove.GetComponent(Components.Powered)
        if lightComponent.IsActive and lightComponent.Voltage > 0.5 then
            NTMB.UpdateHeaterMachine(stove,"stove")
        end
    end

    for fryer in NTMB.Fryers do

        local lightComponent = fryer.GetComponent(Components.Powered)
        if lightComponent.IsActive and lightComponent.Voltage > 0.5 then
            NTMB.UpdateHeaterMachine(fryer,"fryer")
        end
    end
end

function NTMB.UpdateMachineItems()
    local toRemove = {}
    for item,value in pairs(NTMB.ItemData) do
        if item and not item.Removed then
            NTMB.ItemData[item].temperature = value.temperature-NTMB.MachineDeltatime
            if NTMB.ItemData[item].temperature < -1 then
                table.insert(toRemove,item)
            end
        else
            table.insert(toRemove,item)
        end
    end
    for item in toRemove do
        NTMB.ItemData[item] = nil
    end
end

function NTMB.UpdateHeaterMachine(machine,type)

    for item in machine.OwnInventory.AllItems do

        -- heat up item

        -- if this item isnt being kept track of yet, add it to our table
        if not NTMB.ItemData[item] then
            NTMB.ItemData[item] = {temperature=0}
        end
        NTMB.ItemData[item].temperature = NTMB.ItemData[item].temperature+NTMB.MachineDeltatime*2

        -- go through all recipes and check in order if they apply
        local fittingRecipeFound = false
        for recipeName, recipe in pairs(NTMB.Recipes) do
            if
                recipe.station==type and
                HF.TableContains(recipe.from or {},item.Prefab.Identifier.Value)
            then
                local success = false
                -- check if necessary ingredients are available
                local hasAllNecessaryIngredients = true
                local usedIngredients = {}
                local ingredients = {}
                if item.OwnInventory then
                    for ingredient in item.OwnInventory.AllItems do
                        table.insert(ingredients,ingredient)
                    end
                end
                if recipe.ingredients then
                    local testNecessaryLeft = HF.Clone(recipe.ingredients)
                    for ingredient in ingredients do
                        for ingredientRequired in testNecessaryLeft do
                            local ingredientEatableData = NTMB.ItemToEatableData(ingredient)
                            local availableIdentifier = ingredient.Prefab.Identifier.Value
                            local availableFraction = ingredient.Condition/100
                            if ingredientEatableData.transformToFood then
                                availableIdentifier = ingredientEatableData.transformToFood
                                if ingredientEatableData.transformResetsCondition then
                                    availableFraction=1
                                end
                            end
                            if availableIdentifier == ingredientRequired.id then
                                
                                ingredientRequired.amount = (ingredientRequired.amount or 1) - availableFraction
                                table.insert(usedIngredients,ingredient)
                            end
                        end
                    end
                    for necessary in testNecessaryLeft do
                        if (necessary.amount or 1) > 0 then
                            hasAllNecessaryIngredients = false 
                            break
                        end
                    end
                end
                
                if hasAllNecessaryIngredients then
                    fittingRecipeFound=true
                    if NTMB.ItemData[item].temperature >= (recipe.temperature or 1) then
                        if recipe.type == "turnInto+keepNutrition" then

                            -- construct result eatable data
                            local resultEatableData = HF.Clone(NTMB.ItemToEatableData(item))
                            resultEatableData.nutrients = resultEatableData.nutrients or {}
                            resultEatableData = NTMB.MultiplyNutrition(resultEatableData,recipe.nutritionMultiplier or 1)
    
                            local resultSlot=machine.OwnInventory.FindIndex(item)
                            local resultCondition = resultEatableData.condition or 100
                            Timer.Wait(function()
                                -- spawn in the result
                                HF.SpawnItemPlusFunction(recipe.result,function(params)
                                    params.item.Condition = resultCondition
                                    NTMB.SetDishFromEatableData(params.item,params.data)
                                end,{data=resultEatableData},machine.OwnInventory,resultSlot)
                            
                            end,50)
                            Timer.Wait(function() HF.RemoveItem(item) end,1)
    
                            success = true
                        elseif recipe.type == "turnInto" then
                            local resultSlot=machine.OwnInventory.FindIndex(item)
                            local resultCondition = item.Condition
                            Timer.Wait(function()
                                -- spawn in the result
                                HF.SpawnItemPlusFunction(recipe.result,function(params) params.item.Condition = resultCondition end,{},machine.OwnInventory,resultSlot)
                            end,50)
                            Timer.Wait(function() HF.RemoveItem(item) end,1)
                            success = true
                        elseif recipe.type == "potFluid" then
                            Timer.Wait(function() HF.ReplaceItemIdentifier(item,recipe.result,true) end,1)
                            success = true
                        end
    
                        -- remove necessary ingredients
                        if success and recipe.ingredients then
                            local removeNecessaryLeft = HF.Clone(recipe.ingredients)
                            for ingredientRequired in removeNecessaryLeft do
                                ingredientRequired.amount = ingredientRequired.amount or 1
                            end
                            for ingredient in ingredients do
                                for ingredientRequired in removeNecessaryLeft do
                                    local ingredientEatableData = NTMB.ItemToEatableData(ingredient)
                                    if ingredientRequired.amount > 0 and ingredientEatableData.sourceIdentifier == ingredientRequired.id then
                                        local fractionRemoved = math.min(ingredientEatableData.condition/100,ingredientRequired.amount)
                                        ingredientRequired.amount = ingredientRequired.amount - fractionRemoved
                                        ingredient.Condition = ingredientEatableData.condition - fractionRemoved*100
                                        if ingredientEatableData.sourceIdentifier ~= ingredient.Prefab.Identifier.Value then
                                            HF.ReplaceItemIdentifier(ingredient,ingredientEatableData.sourceIdentifier,true)
                                        elseif ingredient.Condition <= 0.1 then
                                            Timer.Wait(function()
                                                HF.RemoveItem(ingredient)
                                            end,50)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

                if success then break end
            end
        end

        -- fryer default recipe
        if type=="fryer" and (not HF.ItemHasTag(item,"finalFryerResult")) and (not fittingRecipeFound) and NTMB.ItemData[item].temperature >= 10 then
            local resultSlot=machine.OwnInventory.FindIndex(item)
            Timer.Wait(function()
                -- spawn in the result
                HF.SpawnItemPlusFunction("friedblob",nil,nil,machine.OwnInventory,resultSlot)
            end,50)
            Timer.Wait(function() HF.RemoveItem(item) end,1)
        end
    end

end


--[[

    if NTMB.Ingredients[item.Prefab.Identifier.Value] and NTMB.Ingredients[item.Prefab.Identifier.Value].oven then
                    local ovenData = NTMB.Ingredients[item.Prefab.Identifier.Value].oven

                    -- if this item isnt being kept track of yet, add it to our table
                    if not NTMB.ItemData[item] then
                        NTMB.ItemData[item] = {temperature=0} end

                    NTMB.ItemData[item].temperature = NTMB.ItemData[item].temperature+NTMB.MachineDeltatime*2

                    if (ovenData.temperature or 10) <= NTMB.ItemData[item].temperature then

                        -- making items turn into other items in the oven
                        if ovenData.type=="turninto" then
                            Timer.Wait(function()
                                local targetslot = oven.OwnInventory.FindIndex(item)
                                HF.RemoveItem(item)
                                Timer.Wait(function()
                                    HF.SpawnItemPlusFunction(ovenData.result,nil,nil,oven.OwnInventory,targetslot)
                                end,1)
                            end,1)

                        -- turninto but keeping and modifying nutrition data
                        elseif ovenData.type=="process" then
                            Timer.Wait(function()
                                local targetslot = oven.OwnInventory.FindIndex(item)
                                local nutritionData = NTMB.ItemToEatableData(item)

                                if nutritionData and ovenData.nutritionMultiplier then
                                    nutritionData = NTMB.MultiplyNutrition(nutritionData,ovenData.nutritionMultiplier)
                                end

                                HF.RemoveItem(item)
                                Timer.Wait(function()
                                    HF.SpawnItemPlusFunction(ovenData.result,function(params)
                                        NTMB.SetDishFromEatableData(params.item,params.data)
                                    end,{data=nutritionData},oven.OwnInventory,targetslot)
                                end,1)
                            end,1)

                        -- make items turn into fucking FIRE AND FLAMES HOLY SHIT
                        elseif ovenData.type=="fire" then
                            Timer.Wait(function()
                                FireSource(item.WorldPosition, nil, true)
                                HF.RemoveItem(item)
                            end,1)

                        -- make items explode
                        elseif ovenData.type=="explosion" then
                            Timer.Wait(function()
                                HF.Explode(item,ovenData.range or 1, ovenData.force or 1, ovenData.damage or 1)
                                HF.SpawnItemAt("ntvfx_explosion",item.WorldPosition)
                                
                                HF.RemoveItem(item)
                            end,1)
                        end
                    end
                end

]]