
NTTut.signalReceivedMethods = {}
NTTut.signalProcessingMethods = {}
NTTut.signalCache = {}

local function SpawnSubject(position,name)
    local info = CharacterInfo("human", name or "Robert")
    info.Job = Job(JobPrefab.Get("assistant"))
    local character = Character.Create(info, position, tostring(math.random(0, 1000000)), 0, false, true)
    character.TeamID = CharacterTeamType.Team1

    if CLIENT and Game.GameSession ~= nil then
        character.TeamID = CharacterTeamType.Team1
        Game.GameSession.CrewManager.AddCharacter(character)         
    end

    character.GiveJobItems()
    character.Info.StartItemsGiven = true

    local orderPrefab = OrderPrefab.Prefabs["wait"]

    local hull = Hull.FindHull(position)
    local order = Order(orderPrefab, OrderTarget(position, hull)).WithManualPriority(CharacterInfo.HighestManualOrderPriority)

    character.SetOrder(order, true, false, true)

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
    -- bone corridor
    dislocations={
        startfunc=function(item,data)
            Timer.Wait(function()
                local character = SpawnSubject(item.WorldPosition,"D. Slocation")
                NT.DislocateLimb(character,LimbType.LeftArm,100)
                NT.DislocateLimb(character,LimbType.RightArm,100)
                NT.DislocateLimb(character,LimbType.LeftLeg,100)
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
                Timer.Wait(function()
                    HF.GiveItem(character,"alienblood")
                    HF.GiveItem(character,"streptokinase")
                    HF.GiveItem(character,"antibloodloss2")
                    HF.GiveItem(character,"bloodpackaplus")
                    HF.GiveItem(character,"bloodanalyzer")
                end,1)
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

