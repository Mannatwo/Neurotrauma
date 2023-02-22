-- I'm sorry for the eyes of anyone looking at the GUI code.

local MultiLineTextBox = dofile(NT.Path .. "/Lua/Scripts/Client/MultiLineTextBox.lua")

Game.AddCommand("neuro", "opens neurotrauma config", function ()
    NT.ToggleGUI()
end)

local function CommaStringToTable(str)
    local tbl = {}

    for word in string.gmatch(str, '([^,]+)') do
        table.insert(tbl, word)
    end

    return tbl
end
local function ClearElements(guicomponent, removeItself)
    local toRemove = {}

    for value in guicomponent.GetAllChildren() do
        table.insert(toRemove, value)
    end

    for index, value in pairs(toRemove) do
        value.RemoveChild(value)
    end

    if guicomponent.Parent and removeItself then
        guicomponent.Parent.RemoveChild(guicomponent)
    end
end
local function GetAmountOfPrefab(prefabs)
    local amount = 0
    for key, value in prefabs do
        amount = amount + 1
    end

    return amount
end
local function DetermineDifficulty()
    local config = NT.Config

    local difficulty = 0
    local res = ""

    -- default difficulty: 16.5
    difficulty=difficulty
        +HF.Clamp(config.dislocationChance,0,5)
        +HF.Clamp(config.fractureChance*2,0,5)
        +HF.Clamp(config.pneumothoraxChance,0,5)
        +HF.Clamp(config.tamponadeChance,0,3)
        +HF.Clamp(config.heartattackChance*0.5,0,1)
        +HF.Clamp(config.strokeChance*0.5,0,1)
        +HF.Clamp(config.infectionRate*1.5,0,5)
        +HF.Clamp(config.CPRFractureChance*0.5,0,1)
        +HF.Clamp(config.traumaticAmputationChance,0,3)
        +HF.Clamp(config.neurotraumaGain*3,0,10)
        +HF.Clamp(config.organDamageGain*2,0,8)
        +HF.Clamp(config.fibrillationSpeed*1.5,0,8)
        +HF.Clamp(config.gangrenespeed*0.5,0,5)
        +HF.BoolToNum(config.organRejection,0.5)
        +HF.BoolToNum(config.fracturesRemoveCasts,0.5)

    -- normalize to 10
    difficulty = difficulty / 16.5 * 10

    if difficulty > 23 then res="Impossible"
    elseif difficulty > 16 then res="Very hard"
    elseif difficulty > 11 then res="Hard"
    elseif difficulty > 8 then res="Normal"
    elseif difficulty > 6 then res="Easy"
    elseif difficulty > 4 then res="Very easy"
    elseif difficulty > 2 then res="Barely different"
    else res="Vanilla but sutures"
    end

    res = res.." ("..HF.Round(difficulty,1)..")"
    return res
end


Hook.Add("stop", "NT.CleanupGUI", function ()
    if selectedGUIText then
        selectedGUIText.Parent.RemoveChild(selectedGUIText)
    end

    if NT.GUIFrame then
        ClearElements(NT.GUIFrame, true)
    end
end)

NT.ShowGUI = function ()
    local frame = GUI.Frame(GUI.RectTransform(Vector2(0.3, 0.6), GUI.Screen.Selected.Frame.RectTransform, GUI.Anchor.Center))

    NT.GUIFrame = frame

    frame.CanBeFocused = true

    local config = GUI.ListBox(GUI.RectTransform(Vector2(1, 1), frame.RectTransform, GUI.Anchor.BottomCenter))
    
    local closebtn = GUI.Button(GUI.RectTransform(Vector2(0.1, 0.3), frame.RectTransform, GUI.Anchor.TopRight), "X", GUI.Alignment.Center, "GUIButtonSmall")
    closebtn.OnClicked = function ()
        NT.ToggleGUI()
    end

    GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.1), config.Content.RectTransform), "Neurotrauma Config", nil, nil, GUI.Alignment.Center)
    
    GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.2), config.Content.RectTransform), "Note: Only the host can edit the servers config. Enter \"reloadlua\" in console to apply changes. For dedicated servers you need to edit the file config.json, this GUI wont work.", nil, nil, GUI.Alignment.Center, true)
    
    local difficultyText = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.1), config.Content.RectTransform), "Calculated difficulty rating: "..DetermineDifficulty(), nil, nil, GUI.Alignment.Center)

    local function OnChanged()
        difficultyText.Text = "Calculated difficulty rating: "..DetermineDifficulty()
    end
    OnChanged()

    local savebtn = GUI.Button(GUI.RectTransform(Vector2(1, 0.2), config.Content.RectTransform), "Save Config", GUI.Alignment.Center, "GUIButtonSmall")
    savebtn.OnClicked = function ()
        File.Write(NT.Path .. "/config.json", json.serialize(NT.Config))
    end


    

    GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), config.Content.RectTransform), "Neurotrauma gain multiplier", nil, nil, GUI.Alignment.Center, true)
    local neurotraumaGain = GUI.NumberInput(GUI.RectTransform(Vector2(1, 0.1), config.Content.RectTransform), NumberType.Float)
    neurotraumaGain.valueStep = 0.1
    neurotraumaGain.MinValueFloat = 0
    neurotraumaGain.MaxValueFloat = 100
    neurotraumaGain.FloatValue = NT.Config.neurotraumaGain
    neurotraumaGain.OnValueChanged = function ()
        NT.Config.neurotraumaGain = neurotraumaGain.FloatValue
        OnChanged()
    end

    GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), config.Content.RectTransform), "Organ damage gain multiplier", nil, nil, GUI.Alignment.Center, true)
    local organDamageGain = GUI.NumberInput(GUI.RectTransform(Vector2(1, 0.1), config.Content.RectTransform), NumberType.Float)
    organDamageGain.valueStep = 0.1
    organDamageGain.MinValueFloat = 0
    organDamageGain.MaxValueFloat = 100
    organDamageGain.FloatValue = NT.Config.organDamageGain
    organDamageGain.OnValueChanged = function ()
        NT.Config.organDamageGain = organDamageGain.FloatValue
        OnChanged()
    end

    GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), config.Content.RectTransform), "Fibrillation speed multiplier", nil, nil, GUI.Alignment.Center, true)
    local fibrillationSpeed = GUI.NumberInput(GUI.RectTransform(Vector2(1, 0.1), config.Content.RectTransform), NumberType.Float)
    fibrillationSpeed.valueStep = 0.1
    fibrillationSpeed.MinValueFloat = 0
    fibrillationSpeed.MaxValueFloat = 100
    fibrillationSpeed.FloatValue = NT.Config.fibrillationSpeed
    fibrillationSpeed.OnValueChanged = function ()
        NT.Config.fibrillationSpeed = fibrillationSpeed.FloatValue
        OnChanged()
    end

    GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), config.Content.RectTransform), "Infection rate multiplier", nil, nil, GUI.Alignment.Center, true)
    local infectionRate = GUI.NumberInput(GUI.RectTransform(Vector2(1, 0.1), config.Content.RectTransform), NumberType.Float)
    infectionRate.valueStep = 0.1
    infectionRate.MinValueFloat = 0
    infectionRate.MaxValueFloat = 100
    infectionRate.FloatValue = NT.Config.infectionRate
    infectionRate.OnValueChanged = function ()
        NT.Config.infectionRate = infectionRate.FloatValue
        OnChanged()
    end

    GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), config.Content.RectTransform), "Gangrene rate multiplier", nil, nil, GUI.Alignment.Center, true)
    local gangrenespeed = GUI.NumberInput(GUI.RectTransform(Vector2(1, 0.1), config.Content.RectTransform), NumberType.Float)
    gangrenespeed.valueStep = 0.1
    gangrenespeed.MinValueFloat = 0
    gangrenespeed.MaxValueFloat = 100
    gangrenespeed.FloatValue = NT.Config.gangrenespeed
    gangrenespeed.OnValueChanged = function ()
        NT.Config.gangrenespeed = gangrenespeed.FloatValue
        OnChanged()
    end

    GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), config.Content.RectTransform), "Fracture chance multiplier", nil, nil, GUI.Alignment.Center, true)
    local fractureChance = GUI.NumberInput(GUI.RectTransform(Vector2(1, 0.1), config.Content.RectTransform), NumberType.Float)
    fractureChance.valueStep = 0.1
    fractureChance.MinValueFloat = 0
    fractureChance.MaxValueFloat = 100
    fractureChance.FloatValue = NT.Config.fractureChance
    fractureChance.OnValueChanged = function ()
        NT.Config.fractureChance = fractureChance.FloatValue
        OnChanged()
    end

    GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), config.Content.RectTransform), "Dislocation chance multiplier", nil, nil, GUI.Alignment.Center, true)
    local dislocationChance = GUI.NumberInput(GUI.RectTransform(Vector2(1, 0.1), config.Content.RectTransform), NumberType.Float)
    dislocationChance.valueStep = 0.1
    dislocationChance.MinValueFloat = 0
    dislocationChance.MaxValueFloat = 100
    dislocationChance.FloatValue = NT.Config.dislocationChance
    dislocationChance.OnValueChanged = function ()
        NT.Config.dislocationChance = dislocationChance.FloatValue
        OnChanged()
    end

    GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), config.Content.RectTransform), "Traumatic amputation chance multiplier", nil, nil, GUI.Alignment.Center, true)
    local traumaticAmputationChance = GUI.NumberInput(GUI.RectTransform(Vector2(1, 0.1), config.Content.RectTransform), NumberType.Float)
    traumaticAmputationChance.valueStep = 0.1
    traumaticAmputationChance.MinValueFloat = 0
    traumaticAmputationChance.MaxValueFloat = 100
    traumaticAmputationChance.FloatValue = NT.Config.traumaticAmputationChance
    traumaticAmputationChance.OnValueChanged = function ()
        NT.Config.traumaticAmputationChance = traumaticAmputationChance.FloatValue
        OnChanged()
    end

    GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), config.Content.RectTransform), "Pneumothorax chance multiplier", nil, nil, GUI.Alignment.Center, true)
    local pneumothoraxChance = GUI.NumberInput(GUI.RectTransform(Vector2(1, 0.1), config.Content.RectTransform), NumberType.Float)
    pneumothoraxChance.valueStep = 0.1
    pneumothoraxChance.MinValueFloat = 0
    pneumothoraxChance.MaxValueFloat = 100
    pneumothoraxChance.FloatValue = NT.Config.pneumothoraxChance
    pneumothoraxChance.OnValueChanged = function ()
        NT.Config.pneumothoraxChance = pneumothoraxChance.FloatValue
        OnChanged()
    end

    GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), config.Content.RectTransform), "Tamponade chance multiplier", nil, nil, GUI.Alignment.Center, true)
    local tamponadeChance = GUI.NumberInput(GUI.RectTransform(Vector2(1, 0.1), config.Content.RectTransform), NumberType.Float)
    tamponadeChance.valueStep = 0.1
    tamponadeChance.MinValueFloat = 0
    tamponadeChance.MaxValueFloat = 100
    tamponadeChance.FloatValue = NT.Config.tamponadeChance
    tamponadeChance.OnValueChanged = function ()
        NT.Config.tamponadeChance = tamponadeChance.FloatValue
        OnChanged()
    end

    GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), config.Content.RectTransform), "Heart attack chance multiplier", nil, nil, GUI.Alignment.Center, true)
    local heartattackChance = GUI.NumberInput(GUI.RectTransform(Vector2(1, 0.1), config.Content.RectTransform), NumberType.Float)
    heartattackChance.valueStep = 0.1
    heartattackChance.MinValueFloat = 0
    heartattackChance.MaxValueFloat = 100
    heartattackChance.FloatValue = NT.Config.heartattackChance
    heartattackChance.OnValueChanged = function ()
        NT.Config.heartattackChance = heartattackChance.FloatValue
        OnChanged()
    end

    GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), config.Content.RectTransform), "Stroke chance multiplier", nil, nil, GUI.Alignment.Center, true)
    local strokeChance = GUI.NumberInput(GUI.RectTransform(Vector2(1, 0.1), config.Content.RectTransform), NumberType.Float)
    strokeChance.valueStep = 0.1
    strokeChance.MinValueFloat = 0
    strokeChance.MaxValueFloat = 100
    strokeChance.FloatValue = NT.Config.strokeChance
    strokeChance.OnValueChanged = function ()
        NT.Config.strokeChance = strokeChance.FloatValue
        OnChanged()
    end

    GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), config.Content.RectTransform), "CPR Rib break chance multiplier", nil, nil, GUI.Alignment.Center, true)
    local CPRFractureChance = GUI.NumberInput(GUI.RectTransform(Vector2(1, 0.1), config.Content.RectTransform), NumberType.Float)
    CPRFractureChance.valueStep = 0.1
    CPRFractureChance.MinValueFloat = 0
    CPRFractureChance.MaxValueFloat = 100
    CPRFractureChance.FloatValue = NT.Config.CPRFractureChance
    CPRFractureChance.OnValueChanged = function ()
        NT.Config.CPRFractureChance = CPRFractureChance.FloatValue
        OnChanged()
    end

    local disableBotAlgorithms = GUI.TickBox(GUI.RectTransform(Vector2(1, 0.2), config.Content.RectTransform), "Disable bot treatment algorithms (they're laggy)")
    disableBotAlgorithms.Selected = NT.Config.disableBotAlgorithms
    disableBotAlgorithms.OnSelected = function ()
        NT.Config.disableBotAlgorithms = disableBotAlgorithms.State == 3
        OnChanged()
    end

    local organRejection = GUI.TickBox(GUI.RectTransform(Vector2(1, 0.2), config.Content.RectTransform), "Organ rejection")
    organRejection.Selected = NT.Config.organRejection
    organRejection.OnSelected = function ()
        NT.Config.organRejection = organRejection.State == 3
        OnChanged()
    end

    local fracturesRemoveCasts = GUI.TickBox(GUI.RectTransform(Vector2(1, 0.2), config.Content.RectTransform), "Refracturing removes casts")
    fracturesRemoveCasts.Selected = NT.Config.fracturesRemoveCasts
    fracturesRemoveCasts.OnSelected = function ()
        NT.Config.fracturesRemoveCasts = fracturesRemoveCasts.State == 3
        OnChanged()
    end

    -- Surgery Plus specific options
    if NTSP~=nil then

        GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.1), config.Content.RectTransform), "Neurotrauma surgery plus", nil, nil, GUI.Alignment.Center, true)

        local NTSPenableSurgicalInfection = GUI.TickBox(GUI.RectTransform(Vector2(1, 0.2), config.Content.RectTransform), "Surgical infection")
        NTSPenableSurgicalInfection.Selected = NT.Config.NTSPenableSurgicalInfection
        NTSPenableSurgicalInfection.OnSelected = function ()
            NT.Config.NTSPenableSurgicalInfection = NTSPenableSurgicalInfection.State == 3
            OnChanged()
        end

        local NTSPenableSurgerySkill = GUI.TickBox(GUI.RectTransform(Vector2(1, 0.2), config.Content.RectTransform), "Surgery skill")
        NTSPenableSurgerySkill.Selected = NT.Config.NTSPenableSurgerySkill
        NTSPenableSurgerySkill.OnSelected = function ()
            NT.Config.NTSPenableSurgerySkill = NTSPenableSurgerySkill.State == 3
            OnChanged()
        end

    end
    
--[[

-- Multilines

    GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), config.Content.RectTransform), "Client High Priority Items", nil, nil, GUI.Alignment.Center, true)

    local clientHighPriorityItems = MultiLineTextBox(config.Content.RectTransform, "", 0.2)

    clientHighPriorityItems.Text = table.concat(NT.Config.clientItemHighPriority, ",")

    clientHighPriorityItems.OnTextChangedDelegate = function (textBox)
        NT.Config.clientItemHighPriority = CommaStringToTable(textBox.Text)
    end
    
-- Tickboxes

    local hideInGameWires = GUI.TickBox(GUI.RectTransform(Vector2(1, 0.2), config.Content.RectTransform), "Hide In Game Wires")

    hideInGameWires.Selected = NT.Config.hideInGameWires

    hideInGameWires.OnSelected = function ()
        NT.Config.hideInGameWires = hideInGameWires.State == 3
    end

    ]]
end


NT.HideGUI = function()
    if NT.GUIFrame then
        ClearElements(NT.GUIFrame, true)
    end
end

NT.GUIOpen = false
NT.ToggleGUI = function ()
    NT.GUIOpen = not NT.GUIOpen

    if NT.GUIOpen then
        NT.ShowGUI()
    else
        NT.HideGUI()
    end
end