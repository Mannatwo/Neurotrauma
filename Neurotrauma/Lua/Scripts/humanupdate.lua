
NT.UpdateCooldown = 0
NT.UpdateInterval = 120
NT.Deltatime = NT.UpdateInterval/60 -- Time in seconds that transpires between updates

Hook.Add("think", "NT.update", function()
    if HF.GameIsPaused() then return end

    NT.UpdateCooldown = NT.UpdateCooldown-1
    if (NT.UpdateCooldown <= 0) then
        NT.UpdateCooldown = NT.UpdateInterval
        NT.Update()
    end

    NT.TickUpdate()
end)

-- gets run once every two seconds
function NT.Update()
    -- for every human
    for _, character in pairs(Character.CharacterList) do
        if (character.IsHuman and not character.IsDead) then
            -- we spread the characters out over a timespan of half a second so the load isnt done all at once
            Timer.Wait(function()
                NT.UpdateHuman(character)
            end, math.random()*500)
        end
    end

end

function NT.UpdateHuman(character)

    -- pre humanupdate hooks
    for key, val in pairs(NTC.PreHumanUpdateHooks) do
        val(character)
    end

    -- fetch environmental oxygen and bloodamount
    local availableoxygen = HF.Clamp(character.Oxygen,0,100) -- percentile, 0-100
    local bloodloss = HF.GetAfflictionStrength(character,"bloodloss",0)
    local prevbloodloss = bloodloss
    local bloodamount = HF.Clamp(100-bloodloss,0,100)

    -- fetch blood pressure
    local bloodpressureaff = character.CharacterHealth.GetAffliction("bloodpressure")
    local bloodpressure = 100
    local prevbloodpressure=-1
    if(bloodpressureaff~=nil) then
        bloodpressure = HF.Round(bloodpressureaff.Strength)
        prevbloodpressure = bloodpressure
    else -- no blood pressure affliction, add it now
        bloodpressureaff = AfflictionPrefab.Prefabs["bloodpressure"].Instantiate(100,character)
        bloodpressure=100
    end

    -- fetch blood oxygen
    local hypoxemia = HF.GetAfflictionStrength(character,"hypoxemia",0)
    local prevhypoxemia = hypoxemia

    -- fetch states and change the strength of some strengthchange afflictions
    local stasis = HF.HasAffliction(character,"stasis",0.1)
    local t_fracture = HF.HasAffliction(character,"t_fracture",0.1) -- rib fracture
    local t_arterialcut = HF.HasAffliction(character,"t_arterialcut",0.1) -- aorticrupture

    local respiratoryarrest = HF.GetAfflictionStrength(character,"respiratoryarrest",0)
    local removedlung = HF.GetAfflictionStrength(character,"lungremoved",0)
    local prevrespiratoryarrest = respiratoryarrest
    local cardiacarrest = HF.GetAfflictionStrength(character,"cardiacarrest",0)
    local removedheart = HF.GetAfflictionStrength(character,"heartremoved",0)
    local prevcardiacarrest = cardiacarrest
    if(respiratoryarrest > 1 or cardiacarrest > 1) then availableoxygen = 0 end
    local removedbrain = HF.GetAfflictionStrength(character,"brainremoved",0)

    -- organ damage
    local heartdamage = HF.GetAfflictionStrength(character,"heartdamage",0)
    local prevheartdamage = heartdamage
    local lungdamage = HF.GetAfflictionStrength(character,"lungdamage",0)
    local prevlungdamage = lungdamage
    local liverdamage = HF.GetAfflictionStrength(character,"liverdamage",0)
    local prevliverdamage = liverdamage
    local kidneydamage = HF.GetAfflictionStrength(character,"kidneydamage",0)
    local prevkidneydamage = kidneydamage
    local bonedamage = HF.GetAfflictionStrength(character,"bonedamage",0)
    local prevbonedamage = bonedamage
    local organdamage = HF.GetAfflictionStrength(character,"organdamage",0)
    local prevorgandamage = organdamage

    -- sepsis
    local sepsis = HF.GetAfflictionStrength(character,"sepsis",0)
    local prevsepsis = sepsis
    local antibiotics = HF.GetAfflictionStrength(character,"afantibiotics",0)
    if(antibiotics > 0.1) then sepsis = sepsis - NT.Deltatime end
    if(sepsis > 0.1 and not stasis) then sepsis = sepsis + 0.05 * NT.Deltatime end

    -- neurotrauma (yoo is this a reference to the barotrauma mod by the name of neurotrauma? truly unruly.)
    local neurotrauma = HF.GetAfflictionStrength(character,"cerebralhypoxia",0)
    local prevneurotrauma = neurotrauma

    -- immunity
    local immunity = 100
    local previmmunity = 100
    if(HF.HasAffliction(character,"immunity",0.5)) then 
        immunity = HF.GetAfflictionStrength(character,"immunity",0)
        previmmunity = immunity
    else 
        -- no immunity affliction! this shouldn't happen.
        -- it probably got removed by heal all or revive
        -- assume that blood type has also been lost and assign new bloodtype
        immunity = 100
        previmmunity = 0
        NT.TryRandomizeBlood(character)
    end
    immunity = HF.Clamp(immunity+(0.5+immunity/100)*NT.Deltatime,1,100)

    -- radiation sickness
    local rads = HF.GetAfflictionStrength(character,"radiationsickness",0)
    local prevrads = rads
    rads = rads - NT.Deltatime * 0.02

    -- internal bleeding
    local internalbleeding = HF.GetAfflictionStrength(character,"internalbleeding",0)
    local previnternalbleeding = internalbleeding
    internalbleeding = internalbleeding - NT.Deltatime * 0.02
    

    -- acid- and alkalosis
    local acidosis = HF.GetAfflictionStrength(character,"acidosis",0)
    local alkalosis = HF.GetAfflictionStrength(character,"alkalosis",0)
    local prevacidosis = acidosis
    local prevalkalosis = alkalosis
    acidosis = HF.Clamp(acidosis-0.03*NT.Deltatime,0,100)
    alkalosis = HF.Clamp(alkalosis-0.03*NT.Deltatime,0,100)
    if(acidosis > 1 and alkalosis > 1) then 
        local min = math.min(acidosis,alkalosis)
        acidosis = acidosis - min
        alkalosis = alkalosis - min
    end

    -- niche injuries and statuses
    local pneumothorax = HF.GetAfflictionStrength(character,"pneumothorax",0)
    local prevpneumothorax = pneumothorax
    if(pneumothorax > 0) then pneumothorax=pneumothorax+0.5*NT.Deltatime end
    local tamponade = HF.GetAfflictionStrength(character,"tamponade",0)
    local prevtamponade = tamponade
    if(tamponade > 0) then tamponade=tamponade+0.5*NT.Deltatime end
    local hemoshock = HF.GetAfflictionStrength(character,"hemotransfusionshock",0)
    local heartattack = HF.GetAfflictionStrength(character,"heartattack",0)
    local prevheartattack = heartattack
    heartattack = heartattack - NT.Deltatime
    local seizure = HF.GetAfflictionStrength(character,"seizure",0)
    local prevseizure= seizure
    seizure = seizure - NT.Deltatime
    local stroke = HF.GetAfflictionStrength(character,"stroke",0)
    local prevstroke = stroke
    local coma = HF.GetAfflictionStrength(character,"coma",0)
    local prevcoma = coma
    coma = coma - NT.Deltatime/5
    local stun = HF.GetAfflictionStrength(character,"stun",0)
    local prevstun = stun
    local slowdown = HF.GetAfflictionStrength(character,"slowdown",0)
    local prevslowdown = slowdown
    local speedmultiplier = 1
    local traumaticshock = HF.GetAfflictionStrength(character,"traumaticshock",0)

    -- anesthesia and drugs
    local analgesia = HF.GetAfflictionStrength(character,"analgesia",0)
    local anesthesia = HF.GetAfflictionStrength(character,"anesthesia",0)
    local drunk = HF.GetAfflictionStrength(character,"drunk",0)
    local adrenaline = HF.GetAfflictionStrength(character,"afadrenaline",0)
    local thiamine = HF.GetAfflictionStrength(character,"afthiamine",0)
    local streptokinase = HF.GetAfflictionStrength(character,"afstreptokinase",0)
    local mannitol = HF.GetAfflictionStrength(character,"afmannitol",0)
    local sedated = analgesia > 0 or anesthesia > 10 or drunk > 30 or stasis

    -- addiction
    local alcoholwithdrawal = HF.GetAfflictionStrength(character,"alcoholwithdrawal",0)
    local withdrawal = math.max(
        HF.GetAfflictionStrength(character,"opiatewithdrawal",0),
        HF.GetAfflictionStrength(character,"chemwithdrawal",0),
        alcoholwithdrawal)
    local overdose = HF.GetAfflictionStrength(character,"opiateoverdose",0)

    

    -- /// Calculate limbs ///
    local healMultiplier = NTC.GetMultiplier(character,"healingrate")
    local prelimbimmunity = immunity
    local clottingMultiplier = HF.Clamp(1-liverdamage/100,0,1)*healMultiplier*HF.Clamp(1-streptokinase,0,1)
    local bonegrowthCount = 0

    local function updateLimb(character,limbtype)

        local function isExtremity() 
            return not limbtype==LimbType.Torso and not limbtype==LimbType.Head
        end

        -- /// fetch stats ///

        local bandaged = HF.GetAfflictionStrengthLimb(character,limbtype,"bandaged",0)
        local bandagedClamped = HF.Clamp(bandaged,0,1)
        local prevbandaged = bandaged
        local dirtybandage = HF.GetAfflictionStrengthLimb(character,limbtype,"dirtybandage",0)
        local prevdirtybandage = dirtybandage
        -- slowdown on bandage and gypsum
        if bandaged > 0.1 or dirtybandage > 0.1 then speedmultiplier = speedmultiplier * 0.9 end
        local gypsumd = HF.Clamp(HF.GetAfflictionStrengthLimb(character,limbtype,"gypsumcast",0),0,1)
        if (gypsumd > 0.1) then speedmultiplier = speedmultiplier * 0.8 end

        local ointmented = HF.Clamp(HF.GetAfflictionStrengthLimb(character,limbtype,"ointmented",0),0,1)
        local bonegrowth = HF.Clamp(HF.GetAfflictionStrengthLimb(character,limbtype,"bonegrowth",0),0,1)
        if (bonegrowth > 0.1) then bonegrowthCount = bonegrowthCount+1 end
        local bleeding = HF.GetAfflictionStrengthLimb(character,limbtype,"bleeding",0)
        local prevbleeding = bleeding
        -- clotting modification
        if(bleeding > 0 and math.abs(clottingMultiplier-1) > 0.05) then bleeding = bleeding - (clottingMultiplier-1) * 0.1 * NT.Deltatime end

        -- physical damage types
        local burn = HF.GetAfflictionStrengthLimb(character,limbtype,"burn",0)
        local prevburn = burn
        burn = burn - (prelimbimmunity/3000 + bandagedClamped*0.1)*healMultiplier*NT.Deltatime
        local lacerations = HF.GetAfflictionStrengthLimb(character,limbtype,"lacerations",0)
        local prevlacerations = lacerations
        lacerations = lacerations - (prelimbimmunity/3000 + bandagedClamped*0.1)*healMultiplier*NT.Deltatime
        local gunshotwound = HF.GetAfflictionStrengthLimb(character,limbtype,"gunshotwound",0)
        local prevgunshotwound = gunshotwound
        gunshotwound = gunshotwound - (prelimbimmunity/3000 + bandagedClamped*0.1)*healMultiplier*NT.Deltatime
        local bitewounds = HF.GetAfflictionStrengthLimb(character,limbtype,"bitewounds",0)
        local prevbitewounds = bitewounds
        bitewounds = bitewounds - (prelimbimmunity/3000 + bandagedClamped*0.1)*healMultiplier*NT.Deltatime
        local explosiondamage = HF.GetAfflictionStrengthLimb(character,limbtype,"explosiondamage",0)
        local prevexplosiondamage = explosiondamage
        explosiondamage = explosiondamage - (prelimbimmunity/3000 + bandagedClamped*0.1)*healMultiplier*NT.Deltatime
        local blunttrauma = HF.GetAfflictionStrengthLimb(character,limbtype,"blunttrauma",0)
        local prevblunttrauma = blunttrauma
        blunttrauma = blunttrauma - (prelimbimmunity/8000 + bandagedClamped*0.1)*healMultiplier*NT.Deltatime
        local internaldamage = HF.GetAfflictionStrengthLimb(character,limbtype,"internaldamage",0)
        local previnternaldamage = internaldamage
        internaldamage = internaldamage - 0.05*healMultiplier*NT.Deltatime
        -- infection
        local infectedwound = HF.GetAfflictionStrengthLimb(character,limbtype,"infectedwound",0)
        local previnfectedwound = infectedwound
        -- foreign bodies
        local foreignbody = HF.GetAfflictionStrengthLimb(character,limbtype,"foreignbody",0)
        local prevforeignbody = foreignbody
        if(foreignbody < 15) then foreignbody = foreignbody-0.05*healMultiplier*NT.Deltatime end
        -- gangrene
        local gangrene = 0
        local prevgangrene = 0
        if(isExtremity()) then 
            gangrene = HF.GetAfflictionStrengthLimb(character,limbtype,"gangrene",0)
            prevgangrene = gangrene
            if(gangrene < 15 and gangrene > 0) then gangrene = gangrene - 0.01*healMultiplier*NT.Deltatime end
            if(sepsis > 5) then gangrene = gangrene + HF.BoolToNum(HF.Chance(0.1+sepsis/300),1) * NT.Deltatime end
            local arteriesclamp = HF.GetAfflictionStrengthLimb(character,limbtype,"arteriesclamp",0)
            if(arteriesclamp > 0) then gangrene = gangrene + HF.BoolToNum(HF.Chance(0.1),1) * 0.5 * NT.Deltatime end
        end

        -- /// calculate infection and immunity ///
        local hassym_inflammation = infectedwound > 10 or foreignbody > 15
        local infectindex = ( -prelimbimmunity/200 - bandagedClamped*1.5 - ointmented*3 + burn/20 + lacerations/40 + bitewounds/30 + gunshotwound/40 + explosiondamage/40 )*NT.Deltatime
        if(hassym_inflammation) then infectindex = infectindex-0.8*NT.Deltatime end
        local wounddamage = burn+lacerations+gunshotwound+bitewounds+explosiondamage
        if(dirtybandage > 10 and wounddamage > 5) then infectindex = infectindex+(wounddamage/40+dirtybandage/20)*NT.Deltatime end
        infectedwound = infectedwound + infectindex/5
        immunity = immunity - HF.Clamp(infectindex/3,0,10)

        -- turning a bandage into a dirty bandage
        local bandageDirtifySpeed = 0.1 + wounddamage/100 + bleeding/20
        if bandaged > 0 then 
            bandaged=bandaged-bandageDirtifySpeed*NT.Deltatime 
            if bandaged <= 0 then 
                dirtybandage = math.max(dirtybandage,1)
                bandaged = 0
            end
        end
        if dirtybandage > 0 then dirtybandage=dirtybandage+bandageDirtifySpeed*NT.Deltatime end

        -- check for arterial cut triggers and foreign body sepsis
        local foreignbodycutchance = ((HF.Minimum(foreignbody,20)/100)^4)*0.5
        if (bleeding > 80 or HF.Chance(foreignbodycutchance)) then
            if(limbtype==LimbType.RightArm) then HF.AddAfflictionLimb(character,"ra_arterialcut",limbtype,1)
            elseif(limbtype==LimbType.LeftArm) then HF.AddAfflictionLimb(character,"la_arterialcut",limbtype,1)
            elseif(limbtype==LimbType.RightLeg) then HF.AddAfflictionLimb(character,"rl_arterialcut",limbtype,1)
            elseif(limbtype==LimbType.LeftLeg) then HF.AddAfflictionLimb(character,"ll_arterialcut",limbtype,1)
            elseif(limbtype==LimbType.Torso) then HF.AddAfflictionLimb(character,"t_arterialcut",limbtype,1)
            elseif(limbtype==LimbType.Head) then HF.AddAfflictionLimb(character,"h_arterialcut",limbtype,1)
            end
        end

        -- sepsis
        local sepsischance = HF.Minimum(gangrene,15,0) / 400 + HF.Minimum(infectedwound,50) / 1000 + foreignbodycutchance
        if(HF.Chance(sepsischance)) then
            sepsis = sepsis + NT.Deltatime
        end

        -- check for bone death fracture triggers
        if (bonegrowth <= 0.1 and bonedamage > 90 and HF.Chance(0.01)) then 
            if(limbtype==LimbType.RightArm) then HF.AddAfflictionLimb(character,"ra_fracture",limbtype,1)
            elseif(limbtype==LimbType.LeftArm) then HF.AddAfflictionLimb(character,"la_fracture",limbtype,1)
            elseif(limbtype==LimbType.RightLeg) then HF.AddAfflictionLimb(character,"rl_fracture",limbtype,1)
            elseif(limbtype==LimbType.LeftLeg) then HF.AddAfflictionLimb(character,"ll_fracture",limbtype,1)
            elseif(limbtype==LimbType.Torso) then HF.AddAfflictionLimb(character,"t_fracture",limbtype,1)
            elseif(limbtype==LimbType.Head) then
                if(HF.Chance(0.5)) then HF.AddAfflictionLimb(character,"h_fracture",limbtype,1)
                else HF.AddAfflictionLimb(character,"n_fracture",limbtype,1) end
            end
        end

        -- check for spasm trigger
        if (seizure > 0.1) then 
            if(HF.Chance(0.5)) then 
                HF.AddAfflictionLimb(character,"spasm",limbtype,10)
            end
        end

        -- /// apply changes ///

        HF.ApplyAfflictionChangeLimb(character,limbtype,"burn",burn,prevburn,0,200)
        HF.ApplyAfflictionChangeLimb(character,limbtype,"bleeding",bleeding,prevbleeding,0,100)
        HF.ApplyAfflictionChangeLimb(character,limbtype,"lacerations",lacerations,prevlacerations,0,200)
        HF.ApplyAfflictionChangeLimb(character,limbtype,"gunshotwound",gunshotwound,prevgunshotwound,0,200)
        HF.ApplyAfflictionChangeLimb(character,limbtype,"bitewounds",bitewounds,prevbitewounds,0,200)
        HF.ApplyAfflictionChangeLimb(character,limbtype,"explosiondamage",explosiondamage,prevexplosiondamage,0,200)
        HF.ApplyAfflictionChangeLimb(character,limbtype,"blunttrauma",blunttrauma,prevblunttrauma,0,200)
        HF.ApplyAfflictionChangeLimb(character,limbtype,"internaldamage",internaldamage,previnternaldamage,0,200)
        HF.ApplyAfflictionChangeLimb(character,limbtype,"foreignbody",foreignbody,prevforeignbody,0,100)
        HF.ApplyAfflictionChangeLimb(character,limbtype,"infectedwound",infectedwound,previnfectedwound,0,100)
        HF.ApplyAfflictionChangeLimb(character,limbtype,"gangrene",gangrene,prevgangrene,0,100)
        HF.ApplyAfflictionChangeLimb(character,limbtype,"dirtybandage",dirtybandage,prevdirtybandage,0,100)
        HF.ApplyAfflictionChangeLimb(character,limbtype,"bandaged",bandaged,prevbandaged,0,100)
    
        HF.ApplySymptomLimb(character,limbtype,"inflammation",hassym_inflammation,true)
    end

    -- being in stasis completely halts activity in limbs
    if(not stasis) then
        updateLimb(character,LimbType.Torso)
        updateLimb(character,LimbType.Head)
        updateLimb(character,LimbType.LeftLeg)
        updateLimb(character,LimbType.RightLeg)
        updateLimb(character,LimbType.LeftArm)
        updateLimb(character,LimbType.RightArm)

        immunity = HF.Clamp(immunity,1,100)
    end

    -- arm locking
    local la_fracture = HF.GetAfflictionStrength(character,"la_fracture",0)
    local ra_fracture = HF.GetAfflictionStrength(character,"ra_fracture",0)
    local tla_amputation = HF.GetAfflictionStrength(character,"tla_amputation",0)
    local tra_amputation = HF.GetAfflictionStrength(character,"tra_amputation",0)
    local sla_amputation = HF.GetAfflictionStrength(character,"sla_amputation",0)
    local sra_amputation = HF.GetAfflictionStrength(character,"sra_amputation",0)
    local ra_dislocation = HF.GetAfflictionStrength(character,"dislocation3",0)
    local la_dislocation = HF.GetAfflictionStrength(character,"dislocation4",0)
    local t_paralysis = HF.GetAfflictionStrength(character,"t_paralysis",0)
    if(t_paralysis > 0) then speedmultiplier=0 end

    local lockleftarm = not NTC.GetSymptomFalse(character,"lockleftarm") and (NTC.GetSymptom(character,"lockleftarm") or (t_paralysis > 0 or tla_amputation > 0 or sla_amputation > 0) or (HF.GetAfflictionStrengthLimb(character,LimbType.LeftArm,"bandaged",0) <= 0 and la_dislocation > 0) or (HF.GetAfflictionStrengthLimb(character,LimbType.LeftArm,"gypsumcast",0) <= 0 and la_fracture > 0))
    local lockrightarm = not NTC.GetSymptomFalse(character,"lockrightarm") and (NTC.GetSymptom(character,"lockrightarm") or (t_paralysis > 0 or tra_amputation > 0 or sra_amputation > 0) or (HF.GetAfflictionStrengthLimb(character,LimbType.RightArm,"bandaged",0) <= 0 and ra_dislocation > 0) or (HF.GetAfflictionStrengthLimb(character,LimbType.RightArm,"gypsumcast",0) <= 0 and ra_fracture > 0))

    local leftlockitem = character.Inventory.FindItemByIdentifier("armlock2",false)
    local rightlockitem = character.Inventory.FindItemByIdentifier("armlock1",false)
    local leftarmlocked = leftlockitem ~= nil
    local rightarmlocked = rightlockitem ~= nil

    if(leftarmlocked and not lockleftarm) then HF.RemoveItem(leftlockitem) end
    if(rightarmlocked and not lockrightarm) then HF.RemoveItem(rightlockitem) end

    if(not leftarmlocked and lockleftarm) then HF.ForceArmLock(character,"armlock2") end
    if(not rightarmlocked and lockrightarm) then HF.ForceArmLock(character,"armlock1") end

    local lockhands = lockleftarm and lockrightarm

    -- leg function
    local ll_fracture = HF.GetAfflictionStrength(character,"ll_fracture",0)
    local rl_fracture = HF.GetAfflictionStrength(character,"rl_fracture",0)
    local tll_amputation = HF.GetAfflictionStrength(character,"tll_amputation",0)
    local trl_amputation = HF.GetAfflictionStrength(character,"trl_amputation",0)
    local sll_amputation = HF.GetAfflictionStrength(character,"sll_amputation",0)
    local srl_amputation = HF.GetAfflictionStrength(character,"srl_amputation",0)
    local rl_dislocation = HF.GetAfflictionStrength(character,"dislocation1",0)
    local ll_dislocation = HF.GetAfflictionStrength(character,"dislocation2",0)

    local lockleftleg = not NTC.GetSymptomFalse(character,"lockleftleg") and (NTC.GetSymptom(character,"lockleftleg") or (t_paralysis > 0 or tll_amputation > 0 or sll_amputation > 0) or (HF.GetAfflictionStrengthLimb(character,LimbType.LeftLeg,"bandaged",0) <= 0 and ll_dislocation > 0) or (HF.GetAfflictionStrengthLimb(character,LimbType.LeftLeg,"gypsumcast",0) <= 0 and ll_fracture > 0))
    local lockrightleg = not NTC.GetSymptomFalse(character,"lockrightleg") and (NTC.GetSymptom(character,"lockrightleg") or (t_paralysis > 0 or trl_amputation > 0 or srl_amputation > 0) or (HF.GetAfflictionStrengthLimb(character,LimbType.RightLeg,"bandaged",0) <= 0 and rl_dislocation > 0) or (HF.GetAfflictionStrengthLimb(character,LimbType.LeftLeg,"gypsumcast",0) <= 0 and rl_fracture > 0))

    -- wheelchair
    local outerwearItem = character.Inventory.GetItemAt(4)
    local usesWheelchair = outerwearItem ~= nil and outerwearItem.Prefab.Identifier == "wheelchair"
    if usesWheelchair then
        lockleftleg = lockleftarm
        lockrightleg = lockrightarm
    end

    if(lockleftleg or lockrightleg) then speedmultiplier = speedmultiplier*0.5 end

    if(lockleftleg and lockrightleg) then stun = math.max(stun,5) end

    -- /// Calculate afflictions ///

    if(not stasis) then 

        -- bloodloss
        if internalbleeding > 0 then
            bloodloss = bloodloss + internalbleeding * (1/40) * NT.Deltatime
        end

        -- calculate new blood pressure
        local desiredbloodpressure =
            (bloodamount - tamponade/2) * -- halved if full tamponade
            (1+0.5*((liverdamage/100)*(liverdamage/100))) * -- elevated if full liver damage
            (1+0.5*((kidneydamage/100)*(kidneydamage/100))) * -- elevated if full kidney damage
            (1 + alcoholwithdrawal/200 ) * -- elevated if alcohol withdrawal
            ((100-traumaticshock)/100) -- none if full traumatic shock
            * NTC.GetMultiplier(character,"bloodpressure")

        local bloodpressurelerp = 0.2
        if(desiredbloodpressure>bloodpressure) then bloodpressurelerp = bloodpressurelerp/3 end
        bloodpressure = HF.Clamp(HF.Round(HF.Lerp(bloodpressure,desiredbloodpressure,bloodpressurelerp)),5,200)

        -- /// calculate new hypoxemia ///

        -- completely cancel out hypoxemia regeneration if penumothorax is full
        availableoxygen = math.min(availableoxygen,100-pneumothorax/2)
        
        local hypoxemiagain = NTC.GetMultiplier(character,"hypoxemiagain")
        local regularHypoxemiaChange = (availableoxygen-50) / 8
        if regularHypoxemiaChange > 0 then
            -- not enough oxygen, increase hypoxemia
            regularHypoxemiaChange = regularHypoxemiaChange * hypoxemiagain
        else
            regularHypoxemiaChange = regularHypoxemiaChange * 2
        end

        hypoxemia = HF.Clamp(hypoxemia + (
            - math.min(0,(bloodpressure-70) / 7) * hypoxemiagain    -- loss because of low blood pressure (-10 at 0 bp)
            - math.min(0,(bloodamount-60) / 4) * hypoxemiagain      -- loss because of low blood amount (-15 at 0 blood)
            - regularHypoxemiaChange                                -- change because of oxygen in lungs (-6.25 <> +12.5)
        )* NT.Deltatime,0,100)

        -- calculate new neurotrauma
        neurotrauma = neurotrauma + 
            ( -0.1*healMultiplier +                     -- passive regen
            hypoxemia/100 +                             -- from hypoxemia
            HF.Clamp(stroke,0,20)*0.1 +                  -- from stroke
            sepsis/100*0.4 +                            -- from sepsis
            liverdamage/800 +                           -- from liverdamage
            kidneydamage/1000                             -- from kidneydamage
        )*NTC.GetMultiplier(character,"neurotraumagain") -- NTC multiplier
        * (1-HF.Clamp(mannitol,0,0.5))                  -- half if mannitol
        * NT.Deltatime
        neurotrauma = HF.Clamp(neurotrauma,0,200)

        -- /// calculate organ damage ///
        local specificOrganDamageHealMultiplier = NTC.GetMultiplier(character,"anyspecificorgandamage") + HF.Clamp(thiamine,0,1)*4
        local neworgandamage = (sepsis/300 + hypoxemia/400 + math.max(rads-25,0)/400)*NTC.GetMultiplier(character,"anyorgandamage")*NT.Deltatime
        if(stasis) then neworgandamage=0 end
        local function organDamageCalc(damagevalue)
            if (damagevalue >= 99) then return 100 end
            return damagevalue - 0.01 * healMultiplier * specificOrganDamageHealMultiplier * NT.Deltatime
        end
        local function kidneyDamageCalc(damagevalue)
            if (damagevalue >= 99) then return 100 end
            if (damagevalue >= 50) then 
                if (damagevalue <= 51) then return damagevalue end
                return damagevalue - 0.01 * healMultiplier * specificOrganDamageHealMultiplier * NT.Deltatime 
            end
            return damagevalue - 0.02 * healMultiplier * specificOrganDamageHealMultiplier * NT.Deltatime
        end

        heartdamage = organDamageCalc(heartdamage + NTC.GetMultiplier(character,"heartdamagegain")*(neworgandamage + HF.Clamp(heartattack,0,0.5) * NT.Deltatime))
        lungdamage = organDamageCalc(lungdamage + NTC.GetMultiplier(character,"lungdamagegain")*(neworgandamage + math.max(rads-25,0)/800*NT.Deltatime))
        liverdamage = organDamageCalc(liverdamage + NTC.GetMultiplier(character,"liverdamagegain")*neworgandamage)
        kidneydamage = kidneyDamageCalc(kidneydamage + NTC.GetMultiplier(character,"kidneydamagegain")*(neworgandamage + HF.Clamp((bloodpressure-120)/160,0,0.5)*NT.Deltatime*0.5))
        bonedamage = organDamageCalc(bonedamage + NTC.GetMultiplier(character,"bonedamagegain")*(sepsis/500 + hypoxemia/1000 + math.max(rads-25,0)/600)*NT.Deltatime)
        organdamage = organdamage + neworgandamage - 0.03 * healMultiplier * NT.Deltatime

        if(bonedamage < 90) then bonedamage = bonedamage - (0.05 + bonegrowthCount*0.3) * healMultiplier * NT.Deltatime
        elseif(bonegrowthCount >= 6) then bonedamage = bonedamage - 2 * NT.Deltatime end
        if(kidneydamage > 70) then bonedamage = bonedamage + (kidneydamage-70)/30*0.15*NT.Deltatime end
        
    end

    

    -- /// calculate symptoms ///
    -- I am deeply sorry for anyone unfortunate enough to stumble upon this behemoth of code

    if liverdamage >= 99 and not NTC.GetSymptom(character,"sym_hematemesis") and HF.Chance(0.05) then
        -- if liver failed: 5% chance for 6-20 seconds of blood vomiting and internal bleeding
        NTC.SetSymptomTrue(character,"sym_hematemesis",math.random(3,10))
        internalbleeding = internalbleeding+2
    end
    if kidneydamage >= 60 and not NTC.GetSymptom(character,"sym_vomiting") and HF.Chance((kidneydamage-60)/40*0.07) then
        -- at 60% kidney damage: 0% chance for vomiting
        -- at 100% kidney damage: 7% chance for vomiting
        NTC.SetSymptomTrue(character,"sym_vomiting",math.random(3,10))
    end

    local hassym_unconsciousness = not NTC.GetSymptomFalse(character,"sym_unconsciousness") and ( NTC.GetSymptom(character,"sym_unconsciousness") or stasis or removedbrain > 0 or (character.Vitality <= 0 and not HF.HasAbilityFlag(character,12)) or neurotrauma > 100 or coma > 15 or hypoxemia > 80 or t_arterialcut or seizure > 0.1 )
    local hassym_tachycardia = not NTC.GetSymptomFalse(character,"tachycardia") and cardiacarrest < 1 and (NTC.GetSymptom(character,"tachycardia") or sepsis > 20 or bloodamount < 60 or bloodpressure < 80 or acidosis > 20 or pneumothorax > 30 or t_arterialcut or adrenaline > 1 or alcoholwithdrawal > 75)
    local hassym_hyperventilation = not NTC.GetSymptomFalse(character,"hyperventilation") and respiratoryarrest < 1 and (NTC.GetSymptom(character,"hyperventilation") or hypoxemia > 10 or bloodpressure < 80 or pneumothorax > 15 or sepsis > 15)
    local hassym_hypoventilation = not NTC.GetSymptomFalse(character,"hypoventilation") and respiratoryarrest < 1 and (NTC.GetSymptom(character,"hypoventilation") or analgesia > 20 or anesthesia > 40)
    if(hassym_hyperventilation and hassym_hypoventilation) then 
        hassym_hyperventilation = false
        hassym_hypoventilation = false
    end
    local hassym_dyspnea = not NTC.GetSymptomFalse(character,"dyspnea") and respiratoryarrest < 1 and (NTC.GetSymptom(character,"dyspnea") or heartattack > 1 or heartdamage > 80 or hypoxemia > 20 or lungdamage > 45 or pneumothorax > 40 or tamponade > 10 or (hemoshock>0 and hemoshock < 70))
    local hassym_cough = not NTC.GetSymptomFalse(character,"sym_cough") and not hassym_unconsciousness and (NTC.GetSymptom(character,"sym_cough") or lungdamage > 50 or heartdamage > 50 or tamponade > 20)
    local hassym_paleskin = not NTC.GetSymptomFalse(character,"sym_paleskin") and (NTC.GetSymptom(character,"sym_paleskin") or bloodamount < 60 or bloodpressure < 50)
    local hassym_lightheadedness = not NTC.GetSymptomFalse(character,"sym_lightheadedness") and not hassym_unconsciousness and (NTC.GetSymptom(character,"sym_lightheadedness") or bloodpressure < 60)
    local hassym_blurredvision = not NTC.GetSymptomFalse(character,"sym_blurredvision") and not hassym_unconsciousness and (NTC.GetSymptom(character,"sym_blurredvision") or bloodpressure < 55)
    local hassym_confusion = not NTC.GetSymptomFalse(character,"sym_confusion") and not hassym_unconsciousness and (NTC.GetSymptom(character,"sym_confusion") or acidosis > 15 or bloodpressure < 30 or hypoxemia > 50 or sepsis > 40 or alcoholwithdrawal > 80)
    local hassym_headache = not NTC.GetSymptomFalse(character,"sym_headache") and not hassym_unconsciousness and not sedated and (NTC.GetSymptom(character,"sym_headache") or bloodamount < 50 or acidosis > 20 or stroke > 1 or hypoxemia > 40 or bloodpressure < 60 or alcoholwithdrawal > 50 or HF.HasAffliction(character,"h_fracture",1))
    local hassym_legswelling = not NTC.GetSymptomFalse(character,"sym_legswelling") and HF.GetAfflictionStrength(character,"rl_cyber",0) < 0.1 and (NTC.GetSymptom(character,"sym_legswelling") or liverdamage > 40 or kidneydamage > 60 or heartdamage > 80)
    local hassym_weakness = not NTC.GetSymptomFalse(character,"sym_weakness") and not hassym_unconsciousness and (NTC.GetSymptom(character,"sym_weakness") or tamponade > 30 or bloodamount < 40 or acidosis > 35)
    local hassym_wheezing = not NTC.GetSymptomFalse(character,"sym_wheezing") and respiratoryarrest < 1 and (NTC.GetSymptom(character,"sym_wheezing") or (hemoshock>0 and hemoshock < 90))
    local hassym_vomiting = not NTC.GetSymptomFalse(character,"sym_vomiting") and (NTC.GetSymptom(character,"sym_vomiting") or drunk > 100 or (hemoshock>0 and hemoshock < 40) or alcoholwithdrawal > 60)
    local hassym_nausea = not NTC.GetSymptomFalse(character,"sym_nausea") and not hassym_unconsciousness and (NTC.GetSymptom(character,"sym_nausea") or kidneydamage > 60 or rads > 80 or (hemoshock>0 and hemoshock < 90) or withdrawal > 40)
    local hassym_vomitingblood = not NTC.GetSymptomFalse(character,"sym_hematemesis") and (NTC.GetSymptom(character,"sym_hematemesis") or internalbleeding > 50)
    local hassym_fever = not NTC.GetSymptomFalse(character,"sym_fever") and (NTC.GetSymptom(character,"sym_fever") or sepsis > 5 or alcoholwithdrawal > 90)
    local hassym_abdomdiscomfort = not NTC.GetSymptomFalse(character,"sym_abdomdiscomfort") and not hassym_unconsciousness and (NTC.GetSymptom(character,"sym_abdomdiscomfort") or liverdamage > 65)
    local hassym_bloating = not NTC.GetSymptomFalse(character,"sym_bloating") and (NTC.GetSymptom(character,"sym_bloating") or liverdamage > 50)
    local hassym_jaundice = not NTC.GetSymptomFalse(character,"sym_jaundice") and (NTC.GetSymptom(character,"sym_jaundice") or liverdamage > 80)
    local hassym_sweating = not NTC.GetSymptomFalse(character,"sym_sweating") and (NTC.GetSymptom(character,"sym_sweating") or heartattack > 1 or withdrawal > 30)
    local hassym_palpitations = not NTC.GetSymptomFalse(character,"sym_palpitations") and cardiacarrest < 1 and (NTC.GetSymptom(character,"sym_palpitations") or alkalosis > 20)
    local hassym_craving = not NTC.GetSymptomFalse(character,"sym_craving") and not hassym_unconsciousness and (NTC.GetSymptom(character,"sym_craving") or withdrawal > 20)
    local hassym_pain_abdominal = not NTC.GetSymptomFalse(character,"pain_abdominal") and not hassym_unconsciousness and not sedated and (NTC.GetSymptom(character,"pain_abdominal") or (hemoshock>0 and hemoshock < 80) or t_arterialcut)
    local hassym_pain_chest = not NTC.GetSymptomFalse(character,"pain_chest") and not hassym_unconsciousness and not sedated and (NTC.GetSymptom(character,"pain_chest") or (hemoshock>0 and hemoshock < 60) or t_fracture or t_arterialcut)

    local triggersym_seizure = not NTC.GetSymptomFalse(character,"triggersym_seizure") and not stasis and (NTC.GetSymptom(character,"triggersym_seizure") or (stroke > 1 and HF.Chance(0.05)) or (acidosis > 60 and HF.Chance(0.05)) or (alkalosis > 60 and HF.Chance(0.05)) or HF.Chance(HF.Minimum(rads,50,0)/200*0.1) or (alcoholwithdrawal > 50 and HF.Chance(alcoholwithdrawal/1000)))
    local triggersym_coma = not NTC.GetSymptomFalse(character,"triggersym_coma") and not stasis and (NTC.GetSymptom(character,"triggersym_coma") or (cardiacarrest > 1 and HF.Chance(0.05)) or (stroke > 1 and HF.Chance(0.05)) or (acidosis > 60 and HF.Chance(0.05+(acidosis-60)/100)))
    local triggersym_stroke = not NTC.GetSymptomFalse(character,"triggersym_stroke") and not stasis and (NTC.GetSymptom(character,"triggersym_stroke") or (bloodpressure > 150 and HF.Chance((bloodpressure-150)/50*0.02+HF.Clamp(streptokinase,0,1)*0.05)))
    local triggersym_heartattack = not NTC.GetSymptomFalse(character,"triggersym_heartattack") and not stasis and streptokinase <= 0 and (NTC.GetSymptom(character,"triggersym_heartattack") or (bloodpressure > 150 and HF.Chance((bloodpressure-150)/50*0.02)))
    local triggersym_cardiacarrest = not NTC.GetSymptomFalse(character,"triggersym_cardiacarrest") and (NTC.GetSymptom(character,"triggersym_cardiacarrest") or stasis or removedheart > 0 or removedbrain > 0 or (heartdamage > 99 and HF.Chance(0.3)) or (traumaticshock > 20 and HF.Chance(0.1)) or ((coma > 40 or hypoxemia > 60 or bloodpressure < 20) and HF.Chance(0.1)))
    local triggersym_respiratoryarrest = not NTC.GetSymptomFalse(character,"triggersym_respiratoryarrest") and (NTC.GetSymptom(character,"triggersym_respiratoryarrest") or stasis or removedlung > 0 or removedbrain > 0 or (lungdamage > 99 and HF.Chance(0.3)) or (traumaticshock > 10 and HF.Chance(0.1)) or ((neurotrauma > 100 or hypoxemia > 70) and HF.Chance(0.1)))

    

    -- /// do some post-symptom calculations ///

    acidosis = acidosis + (HF.BoolToNum(hassym_hypoventilation,1) * 0.13 + math.max(0,kidneydamage - 80)/20*0.1) * NT.Deltatime
    alkalosis = alkalosis + (HF.BoolToNum(hassym_hyperventilation,1) * 0.13) * NT.Deltatime
    stroke = stroke - (1/20)*clottingMultiplier* NT.Deltatime

    if(hassym_vomiting) then speedmultiplier = speedmultiplier*0.8 end
    if(hassym_nausea) then speedmultiplier = speedmultiplier*0.9 end
    if(anesthesia > 0) then speedmultiplier = speedmultiplier*0.5 end
    if(overdose > 50) then speedmultiplier = speedmultiplier*0.5 end

    if(withdrawal > 80) then speedmultiplier = speedmultiplier*0.5
    elseif(withdrawal > 40) then speedmultiplier = speedmultiplier*0.7
    elseif(withdrawal > 20) then speedmultiplier = speedmultiplier*0.9 end

    if(drunk > 80) then speedmultiplier = speedmultiplier*0.5
    elseif(drunk > 40) then speedmultiplier = speedmultiplier*0.7
    elseif(drunk > 20) then speedmultiplier = speedmultiplier*0.8 end

    speedmultiplier = speedmultiplier * NTC.GetSpeedMultiplier(character)
    slowdown = HF.Clamp(100 * (1-speedmultiplier),0,100)

    -- /// Apply changes ///

    HF.ApplyAfflictionChange(character,"bloodloss",bloodloss,prevbloodloss,0,200)
    HF.ApplyAfflictionChange(character,"bloodpressure",bloodpressure,prevbloodpressure,0,200)
    HF.ApplyAfflictionChange(character,"hypoxemia",hypoxemia,prevhypoxemia,0,100)
    HF.ApplyAfflictionChange(character,"heartdamage",heartdamage,prevheartdamage,0,100)
    HF.ApplyAfflictionChange(character,"lungdamage",lungdamage,prevlungdamage,0,100)
    HF.ApplyAfflictionChange(character,"liverdamage",liverdamage,prevliverdamage,0,100)
    HF.ApplyAfflictionChange(character,"kidneydamage",kidneydamage,prevkidneydamage,0,100)
    HF.ApplyAfflictionChange(character,"bonedamage",bonedamage,prevbonedamage,0,100)
    HF.ApplyAfflictionChange(character,"organdamage",organdamage,prevorgandamage,0,200)
    HF.ApplyAfflictionChange(character,"sepsis",sepsis,prevsepsis,0,100)
    HF.ApplyAfflictionChange(character,"cerebralhypoxia",neurotrauma,prevneurotrauma,0,200)
    HF.ApplyAfflictionChange(character,"immunity",immunity,previmmunity,1,100)
    HF.ApplyAfflictionChange(character,"radiationsickness",rads,prevrads,0,200)
    HF.ApplyAfflictionChange(character,"internalbleeding",internalbleeding,previnternalbleeding,0,100)
    HF.ApplyAfflictionChange(character,"acidosis",acidosis,prevacidosis,0,100)
    HF.ApplyAfflictionChange(character,"alkalosis",alkalosis,prevalkalosis,0,100)
    HF.ApplyAfflictionChange(character,"pneumothorax",pneumothorax,prevpneumothorax,0,100)
    HF.ApplyAfflictionChange(character,"tamponade",tamponade,prevtamponade,0,100)
    HF.ApplyAfflictionChange(character,"stun",stun,prevstun,0,100)
    HF.ApplyAfflictionChange(character,"slowdown",slowdown,prevslowdown,0,100)

    HF.ApplyAfflictionChange(character,"heartattack",heartattack + HF.BoolToNum(triggersym_heartattack,50),prevheartattack,0,100)
    HF.ApplyAfflictionChange(character,"seizure",seizure + HF.BoolToNum(triggersym_seizure,10),prevseizure,0,100)
    HF.ApplyAfflictionChange(character,"stroke",stroke + HF.BoolToNum(triggersym_stroke,5),prevstroke,0,100)
    HF.ApplyAfflictionChange(character,"coma",coma + HF.BoolToNum(triggersym_coma,14),prevcoma,0,100)
    HF.ApplyAfflictionChange(character,"cardiacarrest",cardiacarrest + HF.BoolToNum(triggersym_cardiacarrest,10),prevcardiacarrest,0,10)
    HF.ApplyAfflictionChange(character,"respiratoryarrest",respiratoryarrest + HF.BoolToNum(triggersym_respiratoryarrest,10),prevrespiratoryarrest,0,10)

    -- /// Apply symptoms ///

    HF.ApplySymptom(character,"sym_unconsciousness",hassym_unconsciousness,true)
    HF.ApplySymptom(character,"givein",hassym_unconsciousness,true)
    if(hassym_unconsciousness) then HF.SetAffliction(character,"stun",7) end
    HF.ApplySymptom(character,"tachycardia",hassym_tachycardia,true)
    HF.ApplySymptom(character,"hyperventilation",hassym_hyperventilation,true)
    HF.ApplySymptom(character,"hypoventilation",hassym_hypoventilation,true)
    HF.ApplySymptom(character,"dyspnea",hassym_dyspnea,true)
    HF.ApplySymptom(character,"sym_cough",hassym_cough,true)
    HF.ApplySymptom(character,"sym_paleskin",hassym_paleskin,true)
    HF.ApplySymptom(character,"sym_lightheadedness",hassym_lightheadedness,true)
    HF.ApplySymptom(character,"sym_blurredvision",hassym_blurredvision,true)
    HF.ApplySymptom(character,"sym_confusion",hassym_confusion,true)
    HF.ApplySymptom(character,"sym_headache",hassym_headache,true)
    HF.ApplySymptom(character,"sym_legswelling",hassym_legswelling,true)
    HF.ApplySymptom(character,"sym_weakness",hassym_weakness,true)
    HF.ApplySymptom(character,"sym_wheezing",hassym_wheezing,true)
    HF.ApplySymptom(character,"sym_vomiting",hassym_vomiting,true)
    HF.ApplySymptom(character,"sym_nausea",hassym_nausea,true)
    HF.ApplySymptom(character,"sym_hematemesis",hassym_vomitingblood,true)
    HF.ApplySymptom(character,"fever",hassym_fever,true)
    HF.ApplySymptom(character,"sym_abdomdiscomfort",hassym_abdomdiscomfort,true)
    HF.ApplySymptom(character,"sym_bloating",hassym_bloating,true)
    HF.ApplySymptom(character,"sym_jaundice",hassym_jaundice,true)
    HF.ApplySymptom(character,"sym_sweating",hassym_sweating,true)
    HF.ApplySymptom(character,"sym_palpitations",hassym_palpitations,true)
    HF.ApplySymptom(character,"sym_craving",hassym_craving,true)
    HF.ApplySymptom(character,"pain_abdominal",hassym_pain_abdominal,true)
    HF.ApplySymptom(character,"pain_chest",hassym_pain_chest,true)
    HF.ApplySymptom(character,"lockedhands",lockhands,true)

    if HF.GetAfflictionStrength(character,"luabotomy",0) >= 1 then
        HF.SetAffliction(character,"luabotomy",0)
    end
    

    -- compatibility
    NTC.TickCharacter(character)
    -- humanupdate hooks
    for key, val in pairs(NTC.HumanUpdateHooks) do
        val(character)
    end

    NTC.CharacterSpeedMultipliers[character] = nil
end

-- gets run every tick, shouldnt be used unless necessary

function NT.TickUpdate() 
    for key,value in pairs(NT.tickTasks) do 

        value.duration = value.duration-1
        if value.duration <= 0 then 
            NT.tickTasks[key]=nil
        end
    end
end

NT.tickTasks = {}
NT.tickTaskID = 0
function NT.AddTickTask(type,duration,character)
    local newtask = {}
    newtask.type=type
    newtask.duration=duration
    newtask.character=character
    NT.tickTasks[NT.tickTaskID]=newtask
    NT.tickTaskID = NT.tickTaskID+1
end