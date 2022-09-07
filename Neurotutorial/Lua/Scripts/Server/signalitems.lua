
NTTut.signalReceivedMethods = {}
NTTut.signalProcessingMethods = {}
NTTut.signalCache = {}

local function SpawnSubject(position,name,job,team,dontgivejobitems,dontgiveobjective)
    local info = CharacterInfo("human", name or "Robert")
    info.Job = Job(JobPrefab.Get(job or "assistant"))
    local character = Character.Create(info, position, tostring(math.random(0, 1000000)), 0, false, true)
    character.TeamID = team or CharacterTeamType.Team1

    if CLIENT and Game.GameSession ~= nil then
        Game.GameSession.CrewManager.AddCharacter(character)         
    end

    if not dontgivejobitems then
        character.GiveJobItems()
        character.Info.StartItemsGiven = true
    end

    if not dontgiveobjective then
        local orderPrefab = OrderPrefab.Prefabs["wait"]

        local hull = Hull.FindHull(position)
        local order = Order(orderPrefab, OrderTarget(position, hull)).WithManualPriority(CharacterInfo.HighestManualOrderPriority)

        character.SetOrder(order, true, false, true)
    end

    character.Stun = 0.1

    return character
end
local limbTypes = {
    LimbType.LeftArm,
    LimbType.RightArm,
    LimbType.LeftLeg,
    LimbType.RightLeg,
    LimbType.Head,
    LimbType.Torso
}

NTTut.scenarioCache = {}
NTTut.scenarios = {
    test={
        startfunc=function(item,data)
            Timer.Wait(function()
                local character = SpawnSubject(item.WorldPosition)
                HF.AddAffliction(character,"organdamage",50)
                data.character=character
            end,1)
        end,
        endfunc=function(item,data)
            NTTut.HF.RemoveCharacter(data.character)
        end,
        update=function(item,data)
            if data.character == nil then return end

            --if data.character.Stun < 0.5 then
            --    data.character.Stun = 1
            --end

            local state = 1 -- 1: in progress, 0: failed, 2: success
            if data.character == nil then
                state = -1
            elseif data.character.IsDead then
                state=0
            elseif data.character.Vitality / data.character.MaxVitality >= 0.99 then
                state=2
            end

            item.SendSignal(tostring(state), "out_state")
        end
    },
    dummy={
        startfunc=function(item,data)
            Timer.Wait(function()
                local character = SpawnSubject(item.WorldPosition)
                data.character=character
            end,1)
        end,
        endfunc=function(item,data)
            NTTut.HF.RemoveCharacter(data.character)
        end,
        update=function(item,data)
            if data.character == nil then return end

            local state = 1 -- 1: in progress, 0: failed, 2: success
            if data.character == nil then
                state = -1
            elseif data.character.IsDead then
                state=0
            end

            item.SendSignal(tostring(state), "out_state")
        end
    },
    -- bone corridor
    dislocations={
        startfunc=function(item,data)
            Timer.Wait(function()
                local character = SpawnSubject(item.WorldPosition,"D. Slocation")
                NT.DislocateLimb(character,LimbType.LeftArm,100)
                NT.DislocateLimb(character,LimbType.RightArm,100)
                NT.DislocateLimb(character,LimbType.LeftLeg,100)
                HF.GiveItem(character,"opium")
                data.character=character
            end,1)
        end,
        endfunc=function(item,data)
            NTTut.HF.RemoveCharacter(data.character)
        end,
        update=function(item,data)
            if data.character == nil or data.character.Removed then return end

            local state = 1 -- 1: in progress, 0: failed, 2: success
            if data.character == nil then
                state = -1
            elseif data.character.IsDead
                or NT.LimbIsBroken(data.character,LimbType.LeftArm)
                or NT.LimbIsBroken(data.character,LimbType.RightArm)
                or NT.LimbIsBroken(data.character,LimbType.LeftLeg)
            then
                state=0
            elseif
                not NT.LimbIsDislocated(data.character,LimbType.LeftArm)
                and not NT.LimbIsDislocated(data.character,LimbType.RightArm)
                and not NT.LimbIsDislocated(data.character,LimbType.LeftLeg)
             then
                state=2
            end

            item.SendSignal(tostring(state), "out_state")
        end
    },
    fractures={
        startfunc=function(item,data)
            Timer.Wait(function()
                local character = SpawnSubject(item.WorldPosition,"Rick Etts")
                NT.BreakLimb(character,LimbType.LeftArm,100)
                NT.BreakLimb(character,LimbType.RightArm,100)
                NT.BreakLimb(character,LimbType.LeftLeg,100)
                for i = 1,4,1 do HF.GiveItem(character,"antibleeding1") end
                for i = 1,4,1 do HF.GiveItem(character,"gypsum") end
                data.character=character
            end,1)
        end,
        endfunc=function(item,data)
            NTTut.HF.RemoveCharacter(data.character)
        end,
        update=function(item,data)
            if data.character == nil or data.character.Removed then return end

            local state = 1 -- 1: in progress, 0: failed, 2: success
            if data.character == nil then
                state = -1
            elseif data.character.IsDead
            then
                state=0
            elseif
                (not NT.LimbIsBroken(data.character,LimbType.LeftArm) or HF.HasAfflictionLimb(data.character,"gypsumcast",LimbType.LeftArm))
                and (not NT.LimbIsBroken(data.character,LimbType.RightArm) or HF.HasAfflictionLimb(data.character,"gypsumcast",LimbType.RightArm))
                and (not NT.LimbIsBroken(data.character,LimbType.LeftLeg) or HF.HasAfflictionLimb(data.character,"gypsumcast",LimbType.LeftLeg))
            then
                state=2
            end

            item.SendSignal(tostring(state), "out_state")
        end
    },
    skullfracture={
        startfunc=function(item,data)
            Timer.Wait(function()
                local character = SpawnSubject(item.WorldPosition,"Pinhead")
                HF.SetAffliction(character,"h_fracture",100)
                HF.SetAffliction(character,"cerebralhypoxia",20)
                HF.GiveItem(character,"osteosynthesisimplants")
                data.character=character
            end,1)
        end,
        endfunc=function(item,data)
            NTTut.HF.RemoveCharacter(data.character)
        end,
        update=function(item,data)
            if data.character == nil or data.character.Removed then return end

            local state = 1 -- 1: in progress, 0: failed, 2: success
            if data.character == nil then
                state = -1
            elseif data.character.IsDead
            then
                state=0
            elseif
                not HF.HasAffliction(data.character,"h_fracture")
            then
                state=2
            end

            item.SendSignal(tostring(state), "out_state")
        end
    },
    neckfracture={
        startfunc=function(item,data)
            Timer.Wait(function()
                local character = SpawnSubject(item.WorldPosition,"Pinhead")
                HF.SetAffliction(character,"n_fracture",100)
                HF.GiveItem(character,"osteosynthesisimplants")
                HF.GiveItem(character,"spinalimplant")
                data.character=character
            end,1)
        end,
        endfunc=function(item,data)
            NTTut.HF.RemoveCharacter(data.character)
        end,
        update=function(item,data)
            if data.character == nil or data.character.Removed then return end

            local state = 1 -- 1: in progress, 0: failed, 2: success
            if data.character == nil then
                state = -1
            elseif data.character.IsDead
            then
                state=0
            elseif
                not HF.HasAffliction(data.character,"n_fracture")
                and not HF.HasAffliction(data.character,"t_paralysis")
            then
                state=2
            end

            item.SendSignal(tostring(state), "out_state")
        end
    },
    ribfracture={
        startfunc=function(item,data)
            Timer.Wait(function()
                local character = SpawnSubject(item.WorldPosition,"Ribert")
                HF.SetAffliction(character,"t_fracture",100)
                HF.GiveItem(character,"osteosynthesisimplants")
                HF.GiveItem(character,"drainage")
                data.character=character
            end,1)
        end,
        endfunc=function(item,data)
            NTTut.HF.RemoveCharacter(data.character)
        end,
        update=function(item,data)
            if data.character == nil or data.character.Removed then return end

            local state = 1 -- 1: in progress, 0: failed, 2: success
            if data.character == nil then
                state = -1
            elseif data.character.IsDead
            then
                state=0
            elseif
                not HF.HasAffliction(data.character,"t_fracture")
                and not HF.HasAffliction(data.character,"pneumothorax")
            then
                state=2
            end

            item.SendSignal(tostring(state), "out_state")
        end
    },
    bonedeath={
        startfunc=function(item,data)
            Timer.Wait(function()
                local character = SpawnSubject(item.WorldPosition,"Ribert")
                HF.SetAffliction(character,"bonedamage",100)
                HF.GiveItem(character,"osteosynthesisimplants")
                HF.GiveItem(character,"osteosynthesisimplants")
                data.character=character
            end,1)
        end,
        endfunc=function(item,data)
            NTTut.HF.RemoveCharacter(data.character)
        end,
        update=function(item,data)
            if data.character == nil or data.character.Removed then return end

            local state = 1 -- 1: in progress, 0: failed, 2: success
            if data.character == nil then
                state = -1
            elseif data.character.IsDead
            then
                state=0
            elseif
                not HF.HasAffliction(data.character,"bonedamage",90)
            then
                state=2
            end

            item.SendSignal(tostring(state), "out_state")
        end
    },
    -- misc corridor
    burns={
        startfunc=function(item,data)
            Timer.Wait(function()
                local character = SpawnSubject(item.WorldPosition,"Montgomery Burns")
                for t in limbTypes do
                    HF.SetAfflictionLimb(character,"burn",t,50)
                end
                for i = 1,8,1 do HF.GiveItem(character,"antibleeding2") end
                for i = 1,8,1 do HF.GiveItem(character,"ointment") end
                HF.GiveItemPlusFunction("antisepticspray",function(params2)
                    HF.SpawnItemPlusFunction("antiseptic",nil,nil,params2.item.OwnInventory,0)
                end,nil,character)
                data.character=character
            end,1)
        end,
        endfunc=function(item,data)
            NTTut.HF.RemoveCharacter(data.character)
        end,
        update=function(item,data)
            if data.character == nil or data.character.Removed then return end

            local burnsPresent = 0
            for t in limbTypes do
                burnsPresent=burnsPresent+HF.GetAfflictionStrengthLimb(data.character,t,"burn")
            end

            local state = 1 -- 1: in progress, 0: failed, 2: success
            if data.character == nil then
                state = -1
            elseif data.character.IsDead then
                state=0
            elseif
                burnsPresent < 20
                and not HF.HasAffliction(data.character,"sepsis")
            then
                state=2
            end

            item.SendSignal(tostring(state), "out_state")
        end
    },
    -- blood corridor
    alkalosis={
        startfunc=function(item,data)
            Timer.Wait(function()
                local character = SpawnSubject(item.WorldPosition,"Based Barney")
                HF.SetAffliction(character,"alkalosis",30)
                for i = 1,2,1 do HF.GiveItem(character,"antibloodloss1") end
                HF.GiveItem(character,"bloodanalyzer")
                data.character=character
            end,1)
        end,
        endfunc=function(item,data)
            NTTut.HF.RemoveCharacter(data.character)
        end,
        update=function(item,data)
            if data.character == nil or data.character.Removed then return end

            local state = 1 -- 1: in progress, 0: failed, 2: success
            if data.character == nil then
                state = -1
            elseif data.character.IsDead then
                state=0
            elseif
                not HF.HasAffliction(data.character,"alkalosis",5)
            then
                state=2
            end

            item.SendSignal(tostring(state), "out_state")
        end
    },
    acidosis={
        startfunc=function(item,data)
            Timer.Wait(function()
                local character = SpawnSubject(item.WorldPosition,"Cringe Carl")
                HF.SetAffliction(character,"acidosis",30)
                for i = 1,4,1 do HF.GiveItem(character,"raptorbaneextract") end
                HF.GiveItem(character,"bloodanalyzer")
                data.character=character
            end,1)
        end,
        endfunc=function(item,data)
            NTTut.HF.RemoveCharacter(data.character)
        end,
        update=function(item,data)
            if data.character == nil or data.character.Removed then return end

            local state = 1 -- 1: in progress, 0: failed, 2: success
            if data.character == nil then
                state = -1
            elseif data.character.IsDead then
                state=0
            elseif
                not HF.HasAffliction(data.character,"acidosis",5)
                and not HF.HasAffliction(data.character,"tachycardia")
                and not HF.HasAffliction(data.character,"fibrillation")
                and not HF.HasAffliction(data.character,"cardiacarrest")
                and not HF.HasAffliction(data.character,"sym_unconsciousness")
            then
                state=2
            end

            item.SendSignal(tostring(state), "out_state")
        end
    },
    bloodloss={
        startfunc=function(item,data)
            Timer.Wait(function()
                local character = SpawnSubject(item.WorldPosition,"Bleeder Robert")
                HF.SetAffliction(character,"bloodloss",50)
                HF.SetAffliction(character,"bloodpressure",50)
                for i = 1,2,1 do HF.GiveItem(character,"antibloodloss2") end
                HF.GiveItem(character,"bloodanalyzer")
                data.character=character
            end,1)
        end,
        endfunc=function(item,data)
            NTTut.HF.RemoveCharacter(data.character)
        end,
        update=function(item,data)
            if data.character == nil or data.character.Removed then return end

            local state = 1 -- 1: in progress, 0: failed, 2: success
            if data.character == nil then
                state = -1
            elseif data.character.IsDead then
                state=0
            elseif
                HF.GetAfflictionStrength(data.character,"bloodpressure") > 80
                and not HF.HasAffliction(data.character,"tachycardia")
                and not HF.HasAffliction(data.character,"fibrillation")
                and not HF.HasAffliction(data.character,"cardiacarrest")
                and not HF.HasAffliction(data.character,"sym_unconsciousness")
                and not HF.HasAffliction(data.character,"hypoxemia")
            then
                state=2
            end

            item.SendSignal(tostring(state), "out_state")
        end
    },
    hypertension={
        startfunc=function(item,data)
            Timer.Wait(function()
                local character = SpawnSubject(item.WorldPosition,"A. Merican")
                HF.SetAffliction(character,"bloodpressure",150)
                HF.SetAffliction(character,"afadrenaline",100)
                HF.SetAffliction(character,"afringerssolution",100)
                for i = 1,2,1 do HF.GiveItem(character,"pressuremeds") end
                for i = 1,2,1 do HF.GiveItem(character,"nitroglycerin") end
                HF.GiveItem(character,"bloodanalyzer")
                data.character=character
            end,1)
        end,
        endfunc=function(item,data)
            NTTut.HF.RemoveCharacter(data.character)
        end,
        update=function(item,data)
            if data.character == nil or data.character.Removed then return end

            local state = 1 -- 1: in progress, 0: failed, 2: success
            if data.character == nil then
                state = -1
            elseif data.character.IsDead then
                state=0
            elseif
                HF.GetAfflictionStrength(data.character,"bloodpressure") < 120
                and not HF.HasAffliction(data.character,"tachycardia")
                and not HF.HasAffliction(data.character,"fibrillation")
                and not HF.HasAffliction(data.character,"cardiacarrest")
                and not HF.HasAffliction(data.character,"sym_unconsciousness")
                and not HF.HasAffliction(data.character,"stroke")
                and not HF.HasAffliction(data.character,"heartattack")
            then
                state=2
            end

            item.SendSignal(tostring(state), "out_state")
        end
    },
    sepsis={
        startfunc=function(item,data)
            Timer.Wait(function()
                local character = SpawnSubject(item.WorldPosition,"Nas T.")
                HF.SetAffliction(character,"sepsis",50)
                HF.SetAffliction(character,"organdamage",20)
                HF.SetAffliction(character,"heartdamage",20)
                HF.SetAffliction(character,"lungdamage",20)
                HF.SetAffliction(character,"kidneydamage",20)
                HF.SetAffliction(character,"liverdamage",20)
                for i = 1,2,1 do HF.GiveItem(character,"antibiotics") end
                HF.GiveItem(character,"bloodanalyzer")
                data.character=character
            end,1)
        end,
        endfunc=function(item,data)
            NTTut.HF.RemoveCharacter(data.character)
        end,
        update=function(item,data)
            if data.character == nil or data.character.Removed then return end

            local state = 1 -- 1: in progress, 0: failed, 2: success
            if data.character == nil then
                state = -1
            elseif data.character.IsDead then
                state=0
            elseif
                not HF.HasAffliction(data.character,"sepsis")
                and not HF.HasAffliction(data.character,"sym_unconsciousness")
            then
                state=2
            end

            item.SendSignal(tostring(state), "out_state")
        end
    },
    bloodtypes={
        startfunc=function(item,data)
            Timer.Wait(function()
                local character = SpawnSubject(item.WorldPosition,"Robert")
                HF.SetAffliction(character,"bloodloss",25)
                HF.GiveItem(character,"alienblood")
                HF.GiveItem(character,"streptokinase")
                HF.GiveItem(character,"antibloodloss2")
                HF.GiveItem(character,"bloodpackaplus")
                HF.GiveItem(character,"bloodanalyzer")
                data.character=character
            end,1)
        end,
        endfunc=function(item,data)
            NTTut.HF.RemoveCharacter(data.character)
        end,
        update=function(item,data)
            if data.character == nil or data.character.Removed then return end

            local state = 1 -- 1: in progress, 0: failed, 2: success
            if data.character == nil then
                state = -1
            elseif data.character.IsDead then
                state=0
            elseif
                not HF.HasAffliction(data.character,"bloodloss")
                and not HF.HasAffliction(data.character,"hemotransfusionshock")
            then
                state=2
            end

            item.SendSignal(tostring(state), "out_state")
        end
    },
    -- emergency room
    pneumothorax={
        startfunc=function(item,data)
            Timer.Wait(function()
                local character = SpawnSubject(item.WorldPosition,"Lungolf")
                HF.SetAffliction(character,"pneumothorax",100)
                for i = 1,1,1 do HF.GiveItem(character,"needle") end
                for i = 1,1,1 do HF.GiveItem(character,"drainage") end
                data.character=character
            end,1)
        end,
        endfunc=function(item,data)
            NTTut.HF.RemoveCharacter(data.character)
        end,
        update=function(item,data)
            if data.character == nil or data.character.Removed then return end

            local state = 1 -- 1: in progress, 0: failed, 2: success
            if data.character == nil then
                state = -1
            elseif data.character.IsDead then
                state=0
            elseif
                not HF.HasAffliction(data.character,"pneumothorax")
            then
                state=2
            end

            item.SendSignal(tostring(state), "out_state")
        end
    },
    tamponade={
        startfunc=function(item,data)
            Timer.Wait(function()
                local character = SpawnSubject(item.WorldPosition,"Heartie")
                HF.SetAffliction(character,"tamponade",100)
                data.character=character
            end,1)
        end,
        endfunc=function(item,data)
            NTTut.HF.RemoveCharacter(data.character)
        end,
        update=function(item,data)
            if data.character == nil or data.character.Removed then return end

            local state = 1 -- 1: in progress, 0: failed, 2: success
            if data.character == nil then
                state = -1
            elseif data.character.IsDead then
                state=0
            elseif
                not HF.HasAffliction(data.character,"tamponade")
                and not HF.HasAffliction(data.character,"cardiacarrest")
                and not HF.HasAffliction(data.character,"fibrillation")
                and not HF.HasAffliction(data.character,"tachycardia",50)
            then
                state=2
            end

            item.SendSignal(tostring(state), "out_state")
        end
    },
    internalbleeding={
        startfunc=function(item,data)
            Timer.Wait(function()
                local character = SpawnSubject(item.WorldPosition,"Robert")
                HF.SetAffliction(character,"internalbleeding",50)
                HF.GiveItem(character,"antibloodloss2")
                HF.GiveItem(character,"antibloodloss2")
                HF.GiveItem(character,"antibloodloss2")
                data.character=character
            end,1)
        end,
        endfunc=function(item,data)
            NTTut.HF.RemoveCharacter(data.character)
        end,
        update=function(item,data)
            if data.character == nil or data.character.Removed then return end

            local state = 1 -- 1: in progress, 0: failed, 2: success
            if data.character == nil then
                state = -1
            elseif data.character.IsDead then
                state=0
            elseif
                not HF.HasAffliction(data.character,"internalbleeding")
                and not HF.HasAffliction(data.character,"bloodloss")
                and not HF.HasAffliction(data.character,"cardiacarrest")
                and not HF.HasAffliction(data.character,"fibrillation")
                and not HF.HasAffliction(data.character,"tachycardia",50)
            then
                state=2
            end

            item.SendSignal(tostring(state), "out_state")
        end
    },
    aorticrupture={
        startfunc=function(item,data)
            Timer.Wait(function()
                local character = SpawnSubject(item.WorldPosition,"Sir Diesalot")
                HF.SetAffliction(character,"t_arterialcut",50)
                HF.SetAffliction(character,"bloodloss",70)
                HF.SetAffliction(character,"stun",4)
                HF.SetAffliction(character,"sym_unconsciousness",100)
                HF.SetAffliction(character,"fibrillation",20)
                for i = 1,8,1 do HF.GiveItem(character,"antibloodloss2") end
                HF.GiveItem(character,"endovascballoon")
                HF.GiveItem(character,"medstent")
                data.character=character
            end,1)
        end,
        endfunc=function(item,data)
            NTTut.HF.RemoveCharacter(data.character)
        end,
        update=function(item,data)
            if data.character == nil or data.character.Removed then return end

            local state = 1 -- 1: in progress, 0: failed, 2: success
            if data.character == nil then
                state = -1
            elseif data.character.IsDead then
                state=0
            elseif
                not HF.HasAffliction(data.character,"t_arterialcut")
                and not HF.HasAffliction(data.character,"bloodloss",20)
                and not HF.HasAffliction(data.character,"cardiacarrest")
                and not HF.HasAffliction(data.character,"fibrillation")
                and not HF.HasAffliction(data.character,"tachycardia",50)
            then
                state=2
            end

            item.SendSignal(tostring(state), "out_state")
        end
    },
    -- sim center
    mudraptors={
        startfunc=function(item,data)
            Timer.Wait(function()
                local character = SpawnSubject(item.WorldPosition,"Bait")
                data.character=character

                data.raptors = {}
                for i=1,8,1 do
                    local raptor = Character.Create("mudraptor", item.WorldPosition, tostring(math.random(0, 1000000)))
                    table.insert(data.raptors,raptor)
                end

            end,1)
            Timer.Wait(function()
                for raptor in data.raptors do
                    NTTut.HF.RemoveCharacter(raptor)
                end
                data.raptors = {}
            end,10000)
        end,
        endfunc=function(item,data)
            NTTut.HF.RemoveCharacter(data.character)

            for raptor in data.raptors do
                NTTut.HF.RemoveCharacter(raptor)
            end
            data.raptors = {}
        end,
        update=function(item,data)
            if data.character == nil or data.character.Removed then return end

            -- remove raptors early if the patient is at half health
            if data.character.Vitality/data.character.MaxVitality < 0.5 then
                for raptor in data.raptors do
                    NTTut.HF.RemoveCharacter(raptor)
                end
                data.raptors = {}
            end

            local state = 1 -- 1: in progress, 0: failed, 2: success
            if data.character == nil then
                state = -1
            elseif data.character.IsDead then
                state=0
            elseif
                not HF.HasAffliction(data.character,"bloodloss")
                and data.character.Vitality/data.character.MaxVitality > 0.9
                and not HF.HasAffliction(data.character,"fibrillation")
                and not HF.HasAffliction(data.character,"cardiacarrest")
            then
                state=2
            end

            item.SendSignal(tostring(state), "out_state")
        end
    },
    radiation={
        startfunc=function(item,data)
            Timer.Wait(function()
                local character = SpawnSubject(item.WorldPosition,"Glowen")
                HF.SetAffliction(character,"radiationsickness",150)
                HF.SetAffliction(character,"organdamage",40)
                HF.SetAffliction(character,"heartdamage",40)
                HF.SetAffliction(character,"lungdamage",40)
                HF.SetAffliction(character,"kidneydamage",40)
                HF.SetAffliction(character,"liverdamage",40)
                for i = 1,4,1 do HF.GiveItem(character,"antirad") end
                for i = 1,2,1 do HF.GiveItem(character,"thiamine") end
                data.character=character
            end,1)
        end,
        endfunc=function(item,data)
            NTTut.HF.RemoveCharacter(data.character)
        end,
        update=function(item,data)
            if data.character == nil or data.character.Removed then return end

            local state = 1 -- 1: in progress, 0: failed, 2: success
            if data.character == nil then
                state = -1
            elseif data.character.IsDead then
                state=0
            elseif
                not HF.HasAffliction(data.character,"radiationsickness")
                and not HF.HasAffliction(data.character,"sym_unconsciousness")
                and not HF.HasAffliction(data.character,"heartdamage",40)
                and not HF.HasAffliction(data.character,"lungdamage",40)
                and not HF.HasAffliction(data.character,"kidneydamage",40)
                and not HF.HasAffliction(data.character,"liverdamage",40)
            then
                state=2
            end

            item.SendSignal(tostring(state), "out_state")
        end
    },
    bandits={
        startfunc=function(item,data)
            Timer.Wait(function()
                local character = SpawnSubject(item.WorldPosition,"Bait")
                data.character=character

                data.bandits = {}
                for i=1,2,1 do
                    local bandit = SpawnSubject(item.WorldPosition,"Bandit","securityofficer",CharacterTeamType.Team2,true,true)
                    
                    HF.SpawnItemPlusFunction("securityuniform1",nil,nil,bandit.Inventory,3,item.WorldPosition)
                    HF.SpawnItemPlusFunction("bodyarmor",nil,nil,bandit.Inventory,4,item.WorldPosition)
                    HF.SpawnItemPlusFunction("ballistichelmet1",nil,nil,bandit.Inventory,2,item.WorldPosition)
                    HF.SpawnItemPlusFunction("shotgun",function(params)
                        for j=1,6,1 do HF.SpawnItemPlusFunction("shotgunshell",nil,nil,params.item.OwnInventory,0) end
                    end,nil,bandit.Inventory,5,item.WorldPosition)

                    local ai = bandit.AIController
                    ai.AddCombatObjective(AIObjectiveCombat.CombatMode.Offensive, character)
                    
                    table.insert(data.bandits,bandit)
                end

            end,1)
            Timer.Wait(function()
                for bandit in data.bandits do
                    NTTut.HF.RemoveCharacter(bandit)
                end
                data.bandits = {}
            end,10000)
        end,
        endfunc=function(item,data)
            NTTut.HF.RemoveCharacter(data.character)

            for bandit in data.bandits do
                NTTut.HF.RemoveCharacter(bandit)
            end
            data.bandits = {}
        end,
        update=function(item,data)
            if data.character == nil or data.character.Removed then return end

            -- remove bandits early if the patient is knocked out
            if data.character.Vitality/data.character.MaxVitality <= 0 then
                for bandit in data.bandits do
                    NTTut.HF.RemoveCharacter(bandit)
                end
                data.bandits = {}
            end

            local state = 1 -- 1: in progress, 0: failed, 2: success
            if data.character == nil then
                state = -1
            elseif data.character.IsDead then
                state=0
            elseif
                not HF.HasAffliction(data.character,"bloodloss")
                and data.character.Vitality/data.character.MaxVitality > 0.9
                and not HF.HasAffliction(data.character,"fibrillation")
                and not HF.HasAffliction(data.character,"cardiacarrest")
                and not HF.HasAffliction(data.character,"pneumothorax")
                and not HF.HasAffliction(data.character,"tamponade")
                and not HF.HasAffliction(data.character,"internalbleeding")
                and not HF.HasAffliction(data.character,"bleeding")
                and not HF.HasAffliction(data.character,"foreignbody",15)
            then
                state=2
            end

            item.SendSignal(tostring(state), "out_state")
        end
    },
    asphyxiation={
        startfunc=function(item,data)
            Timer.Wait(function()
                local character = SpawnSubject(item.WorldPosition,"Edgegar")
                HF.SetAffliction(character,"oxygenlow",200)
                HF.SetAffliction(character,"stun",10)
                HF.SetAffliction(character,"sym_unconsciousness",10)
                HF.SetAffliction(character,"hypoxemia",100)
                for i = 1,2,1 do HF.GiveItem(character,"liquidoxygenite") end
                for i = 1,2,1 do HF.GiveItem(character,"adrenaline") end
                for i = 1,1,1 do HF.GiveItem(character,"mannitol") end

                HF.SpawnItemPlusFunction("divingsuit",nil,nil,character.Inventory,4,item.WorldPosition)

                data.character=character
            end,1)
        end,
        endfunc=function(item,data)
            NTTut.HF.RemoveCharacter(data.character)
        end,
        update=function(item,data)
            if data.character == nil or data.character.Removed then return end

            local state = 1 -- 1: in progress, 0: failed, 2: success
            if data.character == nil then
                state = -1
            elseif data.character.IsDead then
                state=0
            elseif
                not HF.HasAffliction(data.character,"hypoxemia")
                and not HF.HasAffliction(data.character,"sym_unconsciousness")
                and not HF.HasAffliction(data.character,"oxygenlow")
                and not HF.HasAffliction(data.character,"respiratoryarrest")
                and not HF.HasAffliction(data.character,"cardiacarrest")
                and not HF.HasAffliction(data.character,"tachycardia",20)
                and not HF.HasAffliction(data.character,"fibrillation")
                and not HF.HasAffliction(data.character,"cerebralhypoxia",50)
            then
                state=2
            end

            item.SendSignal(tostring(state), "out_state")
        end
    },
}

NTTut.addSignalToCache = function(signal, connection)
    -- create empty data for the item if not present
    if NTTut.signalCache[connection.Item] == nil then NTTut.signalCache[connection.Item] = {} end

    NTTut.signalCache[connection.Item][connection.Name] = signal.value

    -- lets just hope i am not dumb enough to call one of the connections "Dirty"
    NTTut.signalCache[connection.Item].Dirty = true
end

local function EndScenario(item)
    local data = NTTut.scenarioCache[item]
    if NTTut.scenarios[data.scenario] ~=nil then
        NTTut.scenarios[data.scenario].endfunc(item,data)
    end
end

local function StartScenario(item,scenario)
    if NTTut.scenarioCache[item] ~= nil then
        EndScenario(item)
    end
    local scenarioData = {item=item,scenario=scenario}

    if NTTut.scenarios[scenario] ~=nil then
        NTTut.scenarios[scenario].startfunc(item,scenarioData)
    end

    NTTut.scenarioCache[item] = scenarioData
end

-- signal received hook
Hook.Add("signalReceived", "nttut_signalReceived", function (signal, connection)
    local m = NTTut.signalReceivedMethods[connection.Item.Prefab.Identifier.Value]
    if m then m(signal, connection) end
end)

-- signal processing
-- required for components with >1 input
Hook.Add("think", "nttut_signalProcessing", function ()
    for item, data in pairs(NTTut.signalCache) do
        if data.Dirty then
            local m = NTTut.signalProcessingMethods[item.Prefab.Identifier.Value]
            if m then m(item,data) end
            data.Dirty = false
        end
    end
end)

-- scenario update
Hook.Add("think", "nttut_scenarioupdate", function ()
    for item, data in pairs(NTTut.scenarioCache) do
        if NTTut.scenarios[data.scenario] ~= nil and NTTut.scenarios[data.scenario].update~=nil then
            NTTut.scenarios[data.scenario].update(item,data)
        end
    end
end)

-- scenario component
Hook.Add("nttut_subjectcomponent", "nttut_subjectcomponent", function (effect, deltaTime, item, targets, worldPosition)

    if item == nil or item.Submarine == nil or item.Submarine.SubBody == nil then return 0 end
    
    local memComponents = NTTut.HF.EnumerableToTable(item.GetComponents(Components.MemoryComponent))

    item.SendSignal(memComponents[1].Value, "out_scenario")
    item.SendSignal(memComponents[2].Value, "out_state")
end)
NTTut.signalReceivedMethods.nttut_subjectcomponent = function(signal, connection)
    if signal.value == nil then return end

    if connection.Name == "in_scenario" then
        local memComponents = NTTut.HF.EnumerableToTable(connection.Item.GetComponents(Components.MemoryComponent))
        if memComponents[1] ~= nil then
            memComponents[1].Value = signal.value
            StartScenario(connection.Item,signal.value)
        end
    end
end

