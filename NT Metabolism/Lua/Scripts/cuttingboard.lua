
Hook.Add("ntmb.cuttingboard.process", "ntmb.cuttingboard.process", function (effect, deltaTime, item, targets, worldPosition)
    
    local user = nil

    if SERVER then
        -- sadly lua hooks dont tell us who pressed the button, so it'll just be the closest client for now
        local minDist = 9000
        local itemPos = item.WorldPosition
        for key,client in pairs(Client.ClientList) do
            local char = client.Character
            if char ~= nil and char.IsHuman then
                local dist = HF.Distance(char.WorldPosition,itemPos)
                if dist < minDist then
                    minDist = dist
                    user=char
                end
            end
            
        end
    else 
        user=Character.Controlled
    end

    if not user then return end

    -- wait 250ms so that the description can update
    Timer.Wait(function() NTMB.UseCuttingBoard(item,user) end,50)

end)

Hook.Add("ntmb.cuttingboard.analyze", "ntmb.cuttingboard.analyze", function (effect, deltaTime, item, targets, worldPosition)
    
    local user = nil

    if SERVER then
        -- sadly lua hooks dont tell us who pressed the button, so it'll just be the closest client for now
        local minDist = 9000
        local itemPos = item.WorldPosition
        for key,client in pairs(Client.ClientList) do
            local char = client.Character
            if char ~= nil and char.IsHuman then
                local dist = HF.Distance(char.WorldPosition,itemPos)
                if dist < minDist then
                    minDist = dist
                    user=char
                end
            end
            
        end
    else 
        user=Character.Controlled
    end

    if not user then return end

    -- wait 250ms so that the description can update
    Timer.Wait(function()
        -- fetch necessary items
        local inv = item.OwnInventory
        if inv == nil then return end
        local dish = inv.GetItemAt(0)
        NTMB.AnalyzeDish(dish,user)
    end,50)

end)

function NTMB.UseCuttingBoard(board,user) 

    local skill = NTMB.GetCookingSkill(user)

    -- fetch necessary items
    local inv = board.OwnInventory
    if inv == nil then return end
    local plate = inv.GetItemAt(0)
    local tool = inv.GetItemAt(5)
    local ingredients = {}
    for i = 1, 9, 1 do
        if i ~= 5 then
            local ingredient = inv.GetItemAt(i)
            if ingredient then
                table.insert(ingredients,ingredient)
            end
        end
    end

    local description = ""
    if board.OriginalOutpost ~= "" and board.OriginalOutpost~=nil then
        description=board.OriginalOutpost
    end

    -- go through all recipes and check in order if they apply
    for recipeName, recipe in pairs(NTMB.Recipes) do
        if
            recipe.station=="cuttingboard" and
            ((((not recipe.plate) and (not plate)) or (plate and recipe.plate == plate.Prefab.Identifier.Value)) and
            (((not recipe.tool) and (not tool)) or (tool and recipe.tool == tool.Prefab.Identifier.Value)))
        then
            local success = false
            -- check if necessary ingredients are available
            local hasAllNecessaryIngredients = true
            local usedIngredients = {}
            if recipe.ingredients then
                local testNecessaryLeft = HF.Clone(recipe.ingredients)
                for ingredient in ingredients do
                    for ingredientRequired in testNecessaryLeft do
                        local ingredientEatableData = NTMB.ItemToEatableData(ingredient)
                        local availableIdentifier = ingredientEatableData.sourceIdentifier
                        local availableFraction = ingredientEatableData.condition/100
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
                
                if recipe.type == "freeformAssorted" then
                    local filteredIngredients = NTMB.FilterIngredients(ingredients,recipe.ingredientTag,usedIngredients)
                    print(#filteredIngredients)
                    for ingredient in filteredIngredients do
                        print(ingredient.Prefab.Identifier.Value)
                    end
                    if (#filteredIngredients>0 or #usedIngredients>0) and #filteredIngredients >= (recipe.minimumFreeformIngredients or 0) then

                        -- construct result eatable data
                        local resultEatableData = HF.Clone(NTMB.eatables[recipe.result])
                        resultEatableData.nutrients = resultEatableData.nutrients or {}

                        -- freeform ingredients
                        for ingredient in filteredIngredients do
                            local eatableData = NTMB.ItemToEatableData(ingredient)
                            local fraction = math.min(eatableData.condition/100,eatableData.biteSize or 1)
                            for nutrient,amount in pairs(eatableData.nutrients) do
                                resultEatableData.nutrients[nutrient] = (resultEatableData.nutrients[nutrient] or 0) + amount*fraction*(recipe.nutritionMultiplier or 1)
                            end
                            resultEatableData.weight = (resultEatableData.weight or 0) + (eatableData.weight or 0)*fraction*(recipe.weightMultiplier or 1)
                        end

                        -- required ingredients
                        local removeNecessaryLeft = HF.Clone(recipe.ingredients)
                        for ingredientRequired in removeNecessaryLeft do
                            ingredientRequired.amount = ingredientRequired.amount or 1
                        end
                        for ingredient in usedIngredients do
                            local ingredientEatableData = NTMB.ItemToEatableData(ingredient)
                            local availableIdentifier = ingredientEatableData.sourceIdentifier
                            local availableFraction = ingredientEatableData.condition/100
                            for ingredientRequired in removeNecessaryLeft do
                                if ingredientRequired.amount > 0 and availableIdentifier == ingredientRequired.id then
                                    local nutrientFraction = math.min(availableFraction,ingredientRequired.amount)
                                    ingredientRequired.amount = ingredientRequired.amount - nutrientFraction

                                    for nutrient,amount in pairs(ingredientEatableData.nutrients) do
                                        resultEatableData.nutrients[nutrient] = (resultEatableData.nutrients[nutrient] or 0) + amount*nutrientFraction*(recipe.nutritionMultiplier or 1)
                                    end
                                    resultEatableData.weight = (resultEatableData.weight or 0) + (ingredientEatableData.weight or 0)*nutrientFraction*(recipe.weightMultiplier or 1)
                                end
                            end
                        end

                        -- construct description
                        resultEatableData.description=description

                        if recipe.descriptionType == "showIngredients" then
                            resultEatableData.description=resultEatableData.description.."\n\n"..(recipe.descriptionIngredientHeader or "ingredients")..":"
                            for ingredient in filteredIngredients do
                                local eatableData = NTMB.ItemToEatableData(ingredient)
                                local fraction = math.min(eatableData.condition/100,eatableData.biteSize or 1)
                                local identifier = eatableData.sourceIdentifier or ingredient.Prefab.Identifier.Value
                                resultEatableData.description = resultEatableData.description.."\n- "
                                    ..HF.GetText("entityname."..identifier)
                                if fraction < 0.99 then
                                    resultEatableData.description = resultEatableData.description.." ("
                                    ..tostring(HF.Round(fraction*100)).."%)"
                                end
                            end
                            if #filteredIngredients <= 0 then
                                resultEatableData.description = resultEatableData.description.."\nnone"
                            end
                        end

                        HF.RemoveItem(plate)
                        Timer.Wait(function()
                            -- spawn in the result
                            for i = 1, recipe.yield or 1, 1 do
                                HF.SpawnItemPlusFunction(recipe.result,function(params)
                                    NTMB.SetDishFromEatableData(params.item,params.data)
                                    params.item.Quality = HF.Round(HF.Clamp(skill/100*3,0,3),0)
                                end,{data=resultEatableData},inv,0)
                            end

                        end,50)

                        -- remove ingredients
                        for ingredient in filteredIngredients do
                            local eatableData = NTMB.ItemToEatableData(ingredient)
                            local fraction = math.min(eatableData.condition/100,eatableData.biteSize or 1)
                            if fraction+0.001 >= eatableData.condition/100 then
                                HF.RemoveItem(ingredient)
                            elseif ingredient.Prefab.Identifier.Value ~= eatableData.sourceIdentifier then
                                ingredient.Condition = eatableData.condition-fraction*100
                                HF.ReplaceItemIdentifier(ingredient,eatableData.sourceIdentifier,true)
                            else 
                                ingredient.Condition = eatableData.condition-fraction*100
                            end
                        end

                        success = true
                    end
                elseif recipe.type == "cutUp" then
                    if #usedIngredients>0 then

                        -- determine how many outputs we get and how healthy they are
                        local from = usedIngredients[1]
                        local desiredFraction = 1/(recipe.desiredYield or 1)
                        local availableFraction = from.Condition/100
                        local restFraction = availableFraction

                        -- construct result eatable data
                        local resultEatableData = NTMB.ItemToEatableData(from)
                        resultEatableData.nutrients = resultEatableData.nutrients or {}
                        resultEatableData = NTMB.MultiplyNutrition(resultEatableData,desiredFraction)
                        resultEatableData.weight = (resultEatableData.weight or 1) * desiredFraction

                        -- spawn in the result
                        Timer.Wait(function()
                            HF.SpawnItemPlusFunction("takeoutbag",function(params1)
                            
                                while restFraction>0 do
                                    local outputFraction = math.min(restFraction,desiredFraction)*recipe.desiredYield
                                    local slot = 0
                                    if outputFraction < 1 then slot=1 end
                                        
                                    Timer.Wait(function() 
                                        HF.SpawnItemPlusFunction(recipe.result,function(params)
                                            NTMB.SetDishFromEatableData(params.item,params.data)
                                            params.item.Condition = outputFraction*100
                                        end,{data=resultEatableData},params1.item.OwnInventory,slot)
                                    end,50)

                                    restFraction = restFraction-desiredFraction
                                end
                            end,{},inv,0)
                        end,50)

                        HF.RemoveItem(from)

                        success = true
                    end
                elseif recipe.type == "strict" then

                    -- construct result eatable data
                    local resultEatableData = HF.Clone(NTMB.eatables[recipe.result])
                    resultEatableData.nutrients = resultEatableData.nutrients or {}

                    -- construct description
                    resultEatableData.description=description

                    if recipe.descriptionType == "showIngredients" then
                        resultEatableData.description=resultEatableData.description.."\n\ningredients:"
                        for ingredient in filteredIngredients do
                            local fraction = ingredient.Condition/100
                            local identifier = ingredient.Prefab.Identifier.Value
                            resultEatableData.description = resultEatableData.description.."\n- "
                                ..HF.GetText("entityname."..identifier)
                            if fraction < 0.99 then
                                resultEatableData.description = resultEatableData.description.." ("
                                ..tostring(HF.Round(fraction*100)).."%)"
                            end
                        end
                    end

                    HF.RemoveItem(plate)
                    Timer.Wait(function()
                        -- spawn in the result
                        NTMB.PrintEatableData(resultEatableData)
                        for i = 1, recipe.yield or 1, 1 do
                            HF.SpawnItemPlusFunction(recipe.result,function(params)
                                NTMB.SetDishFromEatableData(params.item,params.data)
                            end,{data=resultEatableData},inv,0)
                        end

                    end,50)

                    success = true
                end

                -- remove necessary ingredients
                if success and recipe.ingredients then
                    local removeNecessaryLeft = HF.Clone(recipe.ingredients)
                    for ingredientRequired in removeNecessaryLeft do
                        ingredientRequired.amount = ingredientRequired.amount or 1
                    end
                    for ingredient in ingredients do
                        local ingredientEatableData = NTMB.ItemToEatableData(ingredient)
                        local availableIdentifier = ingredientEatableData.sourceIdentifier
                        local availableFraction = ingredientEatableData.condition/100
                        for ingredientRequired in removeNecessaryLeft do
                            if ingredientRequired.amount > 0 and availableIdentifier == ingredientRequired.id then
                                local fractionRemoved = math.min(availableFraction,ingredientRequired.amount)
                                ingredientRequired.amount = ingredientRequired.amount - fractionRemoved

                                if availableFraction-fractionRemoved < 0.001 then
                                    Timer.Wait(function()
                                        HF.RemoveItem(ingredient)
                                    end,50)
                                elseif ingredientEatableData.sourceIdentifier ~= ingredient.Prefab.Identifier.Value then
                                    ingredient.Condition = availableFraction*100-fractionRemoved*100
                                    HF.ReplaceItemIdentifier(ingredient,ingredientEatableData.sourceIdentifier,true)
                                else 
                                    ingredient.Condition = availableFraction*100 - fractionRemoved*100
                                end
                            end
                        end
                    end
                end
            end

            if success then break end
        end
    end

    
end



function NTMB.ItemToEatableData(item)
    local identifier = item.Prefab.Identifier.Value
    local condition = item.Condition
    if not HF.ItemHasTag(item,"hasCustomEatableData") then
        local res = NTMB.eatables[identifier] or {nutrients={},weight=1,disableEating=true}
        while res and res.transformToFood do
            local resetCondition = res.transformResetsCondition or false
            identifier = res.transformToFood or identifier
            res = NTMB.eatables[res.transformToFood]
            res.resetCondition = resetCondition
            if res.resetCondition then condition = 100 end
        end
        res.sourceIdentifier = identifier
        res.condition = condition
        return res
    end

    local tags = HF.SplitString(item.Tags,",")
    local res = {nutrients={},tags={},sourceIdentifier=identifier,condition=condition}
    for i, tag in ipairs(tags) do
        if HF.StartsWith(tag,"ntmbw/") then
            local args = HF.SplitString(tag,"/")
            res.weight = tonumber(args[2] or "1")
        elseif HF.StartsWith(tag,"des/") then
            local args = HF.SplitString(tag,"/")
            if #args > 1 then
                res.description = args[2]
            end
        elseif HF.StartsWith(tag,"ntmbl/") then
            local args = HF.SplitString(tag,"/")
            res.leftovers = args[2]
        elseif HF.StartsWith(tag,"col/") then
            local args = HF.SplitString(tag,"/")
            res.color = {tonumber(args[2]),tonumber(args[3]),tonumber(args[4])}
        elseif HF.StartsWith(tag,"ntmbn/") then
            local args = HF.SplitString(tag,"/")
            local nutrient = args[2]
            local amount = tonumber(args[3]) or 0
            res.nutrients[nutrient] = (res.nutrients[nutrient] or 0) + amount

        else
            table.insert(res.tags,tag)
        end
    end
    return res
end
function NTMB.EatableDataToTags(data)
    local res = {"hasCustomEatableData"}

    -- weight
    table.insert(res,"ntmbw/"..tostring(HF.Round(data.weight or 0)))

    -- description
    if data.description ~= nil then
        table.insert(res,"des/"..data.description) end

    -- leftovers
    if data.leftovers ~= nil then
        table.insert(res,"ntmbl/"..data.leftovers) end
        
    -- color
    if data.color ~= nil then 
        table.insert(res,"col/"
        ..tostring(HF.Round(data.color[1])).."/"
        ..tostring(HF.Round(data.color[2])).."/"
        ..tostring(HF.Round(data.color[3]))) end

    -- nutrients
    for nutrient,amount in pairs(data.nutrients) do
        table.insert(res,"ntmbn/"..nutrient.."/"..tostring(amount))
    end

    -- tags
    if data.tags then
        for tag in data.tags do
            table.insert(res,tag)
        end
    end
    
    return res
end
function NTMB.MultiplyNutrition(data,multiplier)
    if not data then return nil end
    local res = HF.Clone(data)
    for nutrient, amount in pairs(data.nutrients) do
        res.nutrients[nutrient] = amount*multiplier
    end
    return res
end
function NTMB.PrintEatableData(data)
    print("printing eatable data")
    for nutrient,amount in pairs(data.nutrients) do
        print(nutrient,":",tostring(amount))
    end
end

LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.Item"], "set_InventoryIconColor")

function NTMB.SetDishFromEatableData(item,data)
    local tags = NTMB.EatableDataToTags(data)
    local tagstring = ""
    for index, value in ipairs(tags) do
        tagstring = tagstring..value
        if index < #tags then tagstring=tagstring.."," end
    end

    item.Tags = tagstring

    if data.description~=nil then
        item.Description = data.description
    end

    if data.color ~=nil then
        local col = Color(data.color[1],data.color[2],data.color[3])
        item.SpriteColor = col
        item.set_InventoryIconColor(col)
        if SERVER then
            local property = item.SerializableProperties[Identifier("InventoryIconColor")]
            Networking.CreateEntityEvent(item, Item.ChangePropertyEventData.__new(property,item))
            property = item.SerializableProperties[Identifier("SpriteColor")]
            Networking.CreateEntityEvent(item, Item.ChangePropertyEventData.__new(property,item))
        end
    end

    
end

function NTMB.RefreshDishDescription(item)
    -- if not HF.ItemHasTag(item,"init") then return end

    local data = NTMB.ItemToEatableData(item)
    if (not data) or (not data.description) then return end

    local identifier = item.Prefab.Identifier.Value
    local prefab = ItemPrefab.GetItemPrefab(identifier)
    local targetinventory = item.ParentInventory
    local targetslot = 0
    local resultCondition = item.Condition
    if targetinventory ~= nil then targetslot = targetinventory.FindIndex(item) end


    local function SpawnFunc(newdishitem,targetinventory)
        if targetinventory~=nil then
            targetinventory.TryPutItem(newdishitem, targetslot,true,true,nil)
        end
        newdishitem.Description = data.description
        newdishitem.Condition = resultCondition
        NTMB.SetDishFromEatableData(newdishitem,data)
    end

    if SERVER then
        item.Drop()
        Entity.Spawner.AddItemToSpawnQueue(prefab, item.WorldPosition, nil, nil, function(newdishitem)
            HF.RemoveItem(item)
            SpawnFunc(newdishitem,targetinventory)
        end)
    else
        -- use client spawn method
        HF.RemoveItem(item)
        local newdishitem = Item(prefab, item.WorldPosition)
        SpawnFunc(newdishitem,targetinventory)
    end
end


Hook.Add("roundStart", "NTMB.RoundStart.Dishrefresh", function()
    Timer.Wait(function()
        NTMB.RefreshAllDishes()
    end,10000) -- maybe 10 seconds is enough?
    
end)

function NTMB.RefreshAllDishes()
    -- descriptions dont get serialized, so i have to respawn
    -- every dish item every round to keep their descriptions (big oof)

    -- fetch dish items
    local dishItems = {}
    for item in Item.ItemList do
        if HF.ItemHasTag(item,"dishItem") then
            table.insert(dishItems,item)
        end
    end
    -- refresh dish items
    for dishItem in dishItems do
        NTMB.RefreshDishDescription(dishItem)
    end
end
Timer.Wait(function()
NTMB.RefreshAllDishes() end,50)


function NTMB.AnalyzeDish(dish,user)
    if not dish then
        HF.DMClient(HF.CharacterToClient(user),"no item in the dish slot!",Color(127,255,127,255))
        return
    end

    if not NTMB.eatables[dish.Prefab.Identifier.Value] then
        HF.DMClient(HF.CharacterToClient(user),"item isn't eatable!",Color(127,255,127,255))
        return
    end

    local eatableData = NTMB.ItemToEatableData(dish)
    local fraction = dish.Condition/100
    local cookingSkill = NTMB.GetCookingSkill(user)

    -- nutritional readout time
    local readoutstring = "Dish analysis of "..HF.GetText("entityname."..dish.Prefab.Identifier.Value)..":\n"

    readoutstring = readoutstring.."weight: "..tostring(HF.Round(eatableData.weight*fraction)).."g\n"
    readoutstring = readoutstring.."nutrients: "
    if cookingSkill < 30 then
        readoutstring = readoutstring.."unlocked at cooking 30"
    else
        local nutrientstring = ""
        local nutrientsDisplayed = 0
        for nutrient,amount in pairs(eatableData.nutrients) do
            local val = NTMB.Nutrients[nutrient]
            print(nutrient,val)
            if not val.hiddenOnReadout then
                local strength = HF.Round(amount,1)

                -- add the nutrient to the readout
                nutrientstring = nutrientstring.."\n"..HF.GetText("ntmb.nutrients."..nutrient)..": "..strength..val.foodUnit
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
    end

    HF.DMClient(HF.CharacterToClient(user),readoutstring,Color(64,255,64,255))
end