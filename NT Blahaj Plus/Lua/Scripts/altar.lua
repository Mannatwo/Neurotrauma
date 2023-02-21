
NTBP.Altars = {}

NTBP.AltarRecipes = {
    blahajplusplus={
        ingredients={
            {slot=7,identifier="blahajplus"},
            {slot=11,identifier="blahajplus"},
            {slot=12,identifier="suture"},
            {slot=13,identifier="blahajplus"},
            {slot=17,identifier="blahajplus"},
        },
        results={
            {slot=12,identifier="blahajplusplus"},
        },
        vfx={
            "ntbpvfx_summon_heavy"
        }
    },
    bpposter_superblahaj={
        ingredients={
            {slot=7,identifier="bpposter_blahaj1"},
            {slot=11,identifier="bpposter_blahaj2"},
            {slot=12,identifier="suture"},
            {slot=13,identifier="bpposter_blahaj3"},
            {slot=17,identifier="bpposter_trans"},
        },
        results={
            {slot=12,identifier="bpposter_superblahaj"},
        }
    },
    skyholderartifact={
        ingredients={
            {slot=7,identifier="blahajplus"},
            {slot=11,identifier="blahajplus"},
            {slot=12,identifier="oxygeniteshard"},
            {slot=13,identifier="blahajplus"},
            {slot=17,identifier="blahajplus"},
        },
        results={
            {slot=12,identifier="skyholderartifact"},
        },
        vfx={
            "ntbpvfx_summon_heavy"
        }
    },
    thermalartifact={
        ingredients={
            {slot=7,identifier="blahajplus"},
            {slot=11,identifier="blahajplus"},
            {slot=12,identifier="incendium"},
            {slot=13,identifier="blahajplus"},
            {slot=17,identifier="blahajplus"},
        },
        results={
            {slot=12,identifier="thermalartifact"},
        },
        vfx={
            "ntbpvfx_summon_heavy"
        }
    },
    faradayartifact={
        ingredients={
            {slot=7,identifier="blahajplus"},
            {slot=11,identifier="blahajplus"},
            {slot=12,identifier="fulgurium"},
            {slot=13,identifier="blahajplus"},
            {slot=17,identifier="blahajplus"},
        },
        results={
            {slot=12,identifier="faradayartifact"},
        },
        vfx={
            "ntbpvfx_summon_heavy"
        }
    },
    nasonovartifact={
        ingredients={
            {slot=7,identifier="blahajplus"},
            {slot=11,identifier="blahajplus"},
            {slot=12,identifier="physicorium"},
            {slot=13,identifier="blahajplus"},
            {slot=17,identifier="blahajplus"},
        },
        results={
            {slot=12,identifier="nasonovartifact"},
        },
        vfx={
            "ntbpvfx_summon_heavy"
        }
    },
    psychosisartifact={
        ingredients={
            {slot=7,identifier="blahajplus"},
            {slot=11,identifier="blahajplus"},
            {slot=12,identifier="dementonite"},
            {slot=13,identifier="blahajplus"},
            {slot=17,identifier="blahajplus"},
        },
        results={
            {slot=12,identifier="psychosisartifact"},
        },
        vfx={
            "ntbpvfx_summon_heavy"
        }
    },
    alienpowercell={
        ingredients={
            {slot=7,identifier="blahaj"},
            {slot=11,identifier="blahaj"},
            {slot=12,identifier="batterycell"},
            {slot=13,identifier="blahaj"},
            {slot=17,identifier="blahaj"},
        },
        results={
            {slot=12,identifier="alienpowercell"},
        },
        vfx={
            "ntbpvfx_summon_heavy"
        }
    },
    alienpistol={
        ingredients={
            {slot=7,identifier="blahaj"},
            {slot=11,identifier="blahaj"},
            {slot=12,identifier="revolver"},
            {slot=13,identifier="blahaj"},
            {slot=17,identifier="blahaj"},
        },
        results={
            {slot=12,identifier="alienpistol"},
        },
        vfx={
            "ntbpvfx_summon_heavy"
        }
    },
    crawler={
        ingredients={
            {slot=12,identifier="blahajplus"},
        },
        results={
            {type="character",identifier="crawler"},
        }
    },
    endworm={
        ingredients={
            {slot=0,identifier="blahajplusplus"},
            {slot=1,identifier="blahajplusplus"},
            {slot=2,identifier="blahajplusplus"},
            {slot=3,identifier="blahajplusplus"},
            {slot=4,identifier="blahajplusplus"},
            {slot=5,identifier="blahajplusplus"},
            {slot=6,identifier="blahajplusplus"},
            {slot=7,identifier="blahajplusplus"},
            {slot=8,identifier="blahajplusplus"},
            {slot=9,identifier="blahajplusplus"},
            {slot=10,identifier="blahajplusplus"},
            {slot=11,identifier="blahajplusplus"},
            {slot=12,identifier="blahajplusplus"},
            {slot=13,identifier="blahajplusplus"},
            {slot=14,identifier="blahajplusplus"},
            {slot=15,identifier="blahajplusplus"},
            {slot=16,identifier="blahajplusplus"},
            {slot=17,identifier="blahajplusplus"},
            {slot=18,identifier="blahajplusplus"},
            {slot=19,identifier="blahajplusplus"},
            {slot=20,identifier="blahajplusplus"},
            {slot=21,identifier="blahajplusplus"},
            {slot=22,identifier="blahajplusplus"},
            {slot=23,identifier="blahajplusplus"},
            {slot=24,identifier="blahajplusplus"},
        },
        results={
            {type="character",identifier="endworm"},
        }
    },
}

Hook.Add("NTBP.altar.start", "NTBP.altar.start", function (effect, deltaTime, item, targets, worldPosition)
    if NTBP.Altars[item] == nil then
        NTBP.Altars[item] = item
    end

    NTBP.AltarBeginPressed(item)

end)

function NTBP.AltarBeginPressed(altar)

    local altarInventory = altar.OwnInventory

    for recipe in NTBP.AltarRecipes do
        
        local ingredientsSatisfied = true
        -- check if all necessary items are present
        local necessaryItems = {}
        for ingredient in recipe.ingredients do
            local itemAtPosition = altarInventory.GetItemAt(ingredient.slot or 0)
            if
                itemAtPosition == nil or
                itemAtPosition.Prefab.Identifier.Value ~= ingredient.identifier
            then
                ingredientsSatisfied = false
            else
                necessaryItems[itemAtPosition] = itemAtPosition
            end
        end

        -- check if theres items that arent supposed to be there
        local extraIngredientsPresent = false
        if ingredientsSatisfied then
            for item in altarInventory.AllItems do
                if necessaryItems[item] == nil then
                    extraIngredientsPresent = true
                end
            end
        end

        -- we're all good!
        if ingredientsSatisfied and not extraIngredientsPresent then
            
            -- remove ingredients
            for item in necessaryItems do
                HF.RemoveItem(item)
            end
            
            -- spawn results
            Timer.Wait(function()
                for result in recipe.results do

                    if result.type == nil or result.type=="item" then
                        HF.SpawnItemPlusFunction(
                            result.identifier,
                            result.postSpawnFunction,
                            necessaryItems,
                            altarInventory,
                            result.slot,
                            altar.WorldPosition)
                    elseif result.type=="character" then
                        Character.Create(
                            result.identifier,
                            altar.WorldPosition,
                            ToolBox.RandomSeed(8));
                    end

                end
            end,recipe.craftdelay or 100)

            -- spawn vfx
            if recipe.vfx~=nil then
                for vfx in recipe.vfx do
                    HF.SpawnItemAt(
                        vfx,
                        altar.WorldPosition)
                end
            end
            
        end
    end
end