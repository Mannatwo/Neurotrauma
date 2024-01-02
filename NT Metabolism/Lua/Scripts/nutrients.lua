local limbtypes = {
    LimbType.Torso,
    LimbType.Head,
    LimbType.LeftArm,
    LimbType.RightArm,
    LimbType.LeftLeg,
    LimbType.RightLeg,
}

-- WARNING: nutrient names should be exclusively lowercase! tags get ToLowered, which messes with nutrient recognition!
NTMB.Nutrients = {
-- Water
    water={
        normalRange={50,70},
        unit="%",
        foodUnit="mL",
        type="water",
        absorptionMultiplier=0.0000125, -- mL to % of body weight (averaged at 80kg)
        idleDrainRate=0.0005,
        exertDrainRate=0.002,
        sweatRate=0.005,
        hiddenOnReadout=false,
        func=function(charID,character,level,i) 

            -- at less than normal, the kidneys suffer
            if level < 50 then
                HF.AddAffliction(character,"kidneydamage",0.025*NTMB.Deltatime)
            end

            -- at less than 40, the person dies
            if level < 40 then
                local damage = (40-level)*10*NTMB.Deltatime

                -- dehydration causes the water to be drawn from the organs and brain, trading damage in those areas for being rehydrated
                HF.AddAffliction(character,"organdamage",damage)
                HF.AddAffliction(character,"liverdamage",damage)
                HF.AddAffliction(character,"kidneydamage",damage)
                HF.AddAffliction(character,"lungdamage",damage)
                HF.AddAffliction(character,"heartdamage",damage)
                HF.AddAffliction(character,"cerebralhypoxia",damage)
                NTMB.SetNutrientLevel(charID,i,40)
            end

            if HF.HasAffliction(character,"sym_sweating") then
                NTMB.AddNutrientLevel(charID,i,-NTMB.Nutrients[i].sweatRate*NTMB.Deltatime)
            end
        end
    },
-- Energy
    fat={
        normalRange={0,2000},
        unit="kcal",
        foodUnit="g",
        type="energy",
        absorptionMultiplier=9, -- kcal/g consumed
        useWeight=1,
        func=function(charID,character,level,i) 

            -- at high levels, cause heart damage
            if level > 1500 then
                HF.AddAffliction(character,"heartdamage",NTMB.Deltatime*0.08)
            end

            -- at very high levels, cause heart attack and stroke, and more heart damage
            if level > 2000 then
                HF.AddAffliction(character,"heartdamage",NTMB.Deltatime*0.07)
                if HF.Chance(NTMB.Deltatime*0.001) then
                    if HF.Chance(0.5) then
                        HF.AddAffliction(character,"heartattack",10)
                    else
                        HF.AddAffliction(character,"stroke",10)
                    end
                end
            end
        end
    },
    protein={
        normalRange={0,2000},
        unit="kcal",
        foodUnit="g",
        type="energy",
        absorptionMultiplier=4,
        useWeight=3
    },
    carbohydrates={
        normalRange={0,2000},
        unit="kcal",
        foodUnit="g",
        type="energy",
        absorptionMultiplier=4,
        useWeight=6,
        func=function(charID,character,level,i) 

            -- at low levels, cause headache
            if level < 200 then
                NTC.SetSymptomTrue(character,"sym_headache",NTMB.Deltatime/NT.Deltatime+1)
            end

            -- at very low levels, cause acidosis and kidney damage
            if level <= 0 then
                HF.AddAffliction(character,"acidosis",NTMB.Deltatime*0.1)
                HF.AddAffliction(character,"kidneydamage",NTMB.Deltatime*0.1)
            end
        end
    },

-- Minerals
    potassium={
        normalRange={3.6,5.2},
        decimals=2,
        unit="mmol/L",
        foodUnit="mg",
        type="mineral",
        absorptionMultiplier=0.0003,
        idleDrainRate=0.0001,
        exertDrainRate=0.0004,
        func=function(charID,character,level,i) 

            -- at low levels, cause tiredness, leg cramps, weakness, arrythmia, hypertension, stroke
            if level < 3 then
                NTC.SetSymptomTrue(character,"sym_weakness",NTMB.Deltatime/NT.Deltatime+1)
                NT.Fibrillate(character,NTMB.Deltatime*(3-level))
                if HF.Chance(NTMB.Deltatime*0.001) then
                    NTC.SetSymptomTrue(character,"triggersym_stroke",1)
                end
            end

            -- at high levels, cause palpitations, pain, weakness, arrythmia
            if level > 6 then
                NTC.SetSymptomTrue(character,"sym_palpitations",NTMB.Deltatime/NT.Deltatime+1)

                if level > 9 then
                    NTC.SetSymptomTrue(character,"sym_weakness",NTMB.Deltatime/NT.Deltatime+1)
                    NT.Fibrillate(character,NTMB.Deltatime*(level-9)*0.5)
                end
            end
        end
    },
    sodium={
        normalRange={135,145},
        decimals=0,
        unit="mmol/L",
        foodUnit="mg",
        type="mineral",
        absorptionMultiplier=0.02,
        idleDrainRate=0.001,
        exertDrainRate=0.004,
        sweatRate=0.014,
        func=function(charID,character,level,i) 

            -- at low levels, cause  loss of appetite, skill loss, headache, nausea, vomiting, confusion, spasms, seizures, coma, death
            -- if very low: neurotrauma, respiratory arrest
            if level < 115 then
                NTC.SetSymptomTrue(character,"sym_headache",NTMB.Deltatime/NT.Deltatime+1)
            end
            -- confusion
            if level < 105 then
                NTC.SetSymptomTrue(character,"sym_confusion",NTMB.Deltatime/NT.Deltatime+1)
            end
            -- nausea and vomiting
            if level < 95 then
                NTC.SetSymptomTrue(character,"sym_nausea",NTMB.Deltatime/NT.Deltatime+1)
                if HF.Chance(NTMB.Deltatime*0.01) then
                    NTC.SetSymptomTrue(character,"sym_vomiting",HF.RandomRange(5,10))
                end
            end
            -- seizures
            if level < 80 then
                if HF.Chance(NTMB.Deltatime*0.01) then
                    NTC.SetSymptomTrue(character,"triggersym_seizure",2)
                end
            end
            -- coma
            if level < 70 then
                if HF.Chance(NTMB.Deltatime*0.01) then
                    HF.AddAffliction(character,"coma",10)
                end
                if HF.Chance(NTMB.Deltatime*0.02) then
                    NTC.SetSymptomTrue(character,"triggersym_seizure",2)

                
                end
            end
            -- respiratory arrest, neurotrauma
            if level < 60 then
                if HF.Chance(NTMB.Deltatime*0.01) then
                    HF.AddAffliction(character,"coma",10)
                end
                if HF.Chance(NTMB.Deltatime*0.02) then
                    NTC.SetSymptomTrue(character,"triggersym_seizure",2)

                end
                if HF.Chance(NTMB.Deltatime*0.02) then
                    HF.AddAffliction(character,"respiratoryarrest",10)
                end
                HF.AddAffliction(character,"cerebralhypoxia",NTMB.Deltatime*(60-level)/60*1.5)
            end

            -- at high levels, cause thirst, weakness, nausea, loss of appetite, confision, twitching, brain bleed, seizures, coma
            if level > 200 then
                if HF.Chance(NTMB.Deltatime*0.02) then
                    HF.AddAffliction(character,"coma",10)
                end
                if HF.Chance(NTMB.Deltatime*0.02) then
                    NTC.SetSymptomTrue(character,"triggersym_seizure",2)

                end
                if HF.Chance(NTMB.Deltatime*0.02) then
                    HF.AddAffliction(character,"stroke",10)
                
                end
            end
            if level > 180 then
                NTC.SetSymptomTrue(character,"sym_confusion",NTMB.Deltatime/NT.Deltatime+1)
            end
            if level > 160 then
                NTC.SetSymptomTrue(character,"sym_weakness",NTMB.Deltatime/NT.Deltatime+1)
            end

            if HF.HasAffliction(character,"sym_sweating") then
                NTMB.AddNutrientLevel(charID,i,-NTMB.Nutrients[i].sweatRate*NTMB.Deltatime)
            end
        end
    },
    magnesium={
        normalRange={600,1100},
        decimals=0,
        unit="μmol/L",
        foodUnit="mg",
        type="mineral",
        absorptionMultiplier=1,
        idleDrainRate=0.025,
        exertDrainRate=0.05,
        func=function(charID,character,level,i) 

            -- at low levels,  tiredness, weakness, cramps, arrythmia, palpitations, seizures, coma, skill issues, death
            -- palpitations
            if level < 500 then
                NTC.SetSymptomTrue(character,"sym_palpitations",NTMB.Deltatime/NT.Deltatime+1)
            end
            -- weakness
            if level < 450 then
                NTC.SetSymptomTrue(character,"sym_weakness",NTMB.Deltatime/NT.Deltatime+1)
            end
            -- arrythmia and seizures
            if level < 350 then
                NT.Fibrillate(character,NTMB.Deltatime * HF.Clamp((350-level)*0.02,0,1))
                if HF.Chance(NTMB.Deltatime*0.01) then
                    NTC.SetSymptomTrue(character,"triggersym_seizure",2)
                end
            end
            -- coma
            if level < 300 then
                if HF.Chance(NTMB.Deltatime*0.01) then
                    HF.AddAffliction(character,"coma",10)
                end
                if HF.Chance(NTMB.Deltatime*0.02) then
                    NTC.SetSymptomTrue(character,"triggersym_seizure",2)
                end
            end

            -- at high levels, cause weakness, confusion, hypoventilation, nausea, low blood pressure, arrythmia, cardiac arrest, respiratory failure
            -- confusion
            if level > 1200 then
                NTC.SetSymptomTrue(character,"sym_confusion",NTMB.Deltatime/NT.Deltatime+1)
            end
            -- weakness, fibrillation
            if level > 1400 then
                NTC.SetSymptomTrue(character,"sym_weakness",NTMB.Deltatime/NT.Deltatime+1)
                NT.Fibrillate(character,NTMB.Deltatime*(level-1400)*0.004)
            end
            -- hypoventilation, nausea
            if level > 1700 then 
                NTC.SetSymptomTrue(character,"hypoventilation",NTMB.Deltatime/NT.Deltatime+1)
                NTC.SetSymptomTrue(character,"sym_nausea",NTMB.Deltatime/NT.Deltatime+1)
            end
            -- respiratory arrest
            if level > 2000 then 
                NTC.SetSymptomTrue(character,"triggersym_respiratoryarrest",2)
            end
            -- cardiac arrest
            if level > 2500 then 
                if HF.Chance(NTMB.Deltatime*0.05) then
                    NTC.SetSymptomTrue(character,"triggersym_cardiacarrest",2)
                end
            end
        end
    },

-- Vitamins
    vitaminb1={
        normalRange={74,222},
        decimals=0,
        unit="nmol/L",
        foodUnit="%",
        type="vitamin",
        absorptionMultiplier=0.1,
        idleDrainRate=0.01,
        exertDrainRate=0.01,
        func=function(charID,character,level,i) 

            -- at low levels, increased heartrate, shortness of breath, leg swelling, confusion, pain, loss of apetite, vomiting
            -- shortness of breath
            if level < 70 then
                NTC.SetSymptomTrue(character,"dyspnea",NTMB.Deltatime/NT.Deltatime+1)
            end
            -- leg swelling
            if level < 65 then
                NTC.SetSymptomTrue(character,"sym_legswelling",NTMB.Deltatime/NT.Deltatime+1)
            end
            -- confusion, pain
            if level < 60 then
                NTC.SetSymptomTrue(character,"sym_confusion",NTMB.Deltatime/NT.Deltatime+1)
                NTC.SetSymptomTrue(character,"pain_abdominal",NTMB.Deltatime/NT.Deltatime+1)
            end
            -- tachycardia and vomiting
            if level < 55 then
                NTC.SetSymptomTrue(character,"tachycardia",NTMB.Deltatime/NT.Deltatime+1)
                if HF.Chance(NTMB.Deltatime*(55-level)*0.01) then
                    NTC.SetSymptomTrue(character,"sym_vomiting",HF.RandomRange(5,10))
                end
            end

            -- no toxicity
        end
    },
    vitaminb12={
        normalRange={148,811},
        decimals=0,
        unit="pmol/L",
        foodUnit="%",
        type="vitamin",
        absorptionMultiplier=0.1,
        idleDrainRate=0.01,
        exertDrainRate=0.01,
        func=function(charID,character,level,i) 

            -- at low levels, tiredness, weakness, lightheadedness, dizziness, headaches, rapid or irregular heartbeat,
            -- breathlessness, fevers, tremor, chest pain low blood pressure, pale skin, upset stomach, nausea,
            -- loss of appetite, weight loss, diarrhea
            -- jesus christ, thats a lot

            -- lightheadedness, weakness
            if level < 140 then
                NTC.SetSymptomTrue(character,"sym_lightheadedness",NTMB.Deltatime/NT.Deltatime+1)
                NTC.SetSymptomTrue(character,"sym_weakness",NTMB.Deltatime/NT.Deltatime+1)
            end
            -- headaches, nausea
            if level < 130 then
                NTC.SetSymptomTrue(character,"sym_headache",NTMB.Deltatime/NT.Deltatime+1)
                NTC.SetSymptomTrue(character,"sym_nausea",NTMB.Deltatime/NT.Deltatime+1)
            end
            -- chest pain, tachycardia, fever
            if level < 120 then
                NTC.SetSymptomTrue(character,"pain_chest",NTMB.Deltatime/NT.Deltatime+1)
                NTC.SetSymptomTrue(character,"tachycardia",NTMB.Deltatime/NT.Deltatime+1)
                NTC.SetSymptomTrue(character,"sym_fever",NTMB.Deltatime/NT.Deltatime+1)
            end
            -- arrythmia, pale skin
            if level < 110 then
                NT.Fibrillate(character,NTMB.Deltatime*(110-level)*0.05)
                NTC.SetSymptomTrue(character,"sym_paleskin",NTMB.Deltatime/NT.Deltatime+1)
            end

            -- no toxicity
        end
    },
    vitaminc={
        normalRange={11.4,50},
        unit="μmol/L",
        foodUnit="%",
        type="vitamin",
        absorptionMultiplier=0.1,
        idleDrainRate=0.001,
        exertDrainRate=0.001,
        func=function(charID,character,level,i) 

            -- at low levels, weakness, fatigue, sore arms and legs, lethargy,
            -- bleeding from skin, poor wound healing, infection, shortness of breath,
            -- bone pain, easy bruising, jaundice, fever, convulsions, death

            -- weakness
            if level < 11 then
                NTC.SetSymptomTrue(character,"sym_weakness",NTMB.Deltatime/NT.Deltatime+1)
            end
            -- shortness of breath
            if level < 10 then
                NTC.SetSymptomTrue(character,"dyspnea",NTMB.Deltatime/NT.Deltatime+1)
            end
            -- jaundice
            if level < 9 then
                NTC.SetSymptomTrue(character,"sym_jaundice",NTMB.Deltatime/NT.Deltatime+1)
            end
            -- fever and reduced immunity
            if level < 8 then
                HF.SetAffliction(character,"immunity",HF.Clamp(
                    HF.GetAfflictionStrength(character,"immunity",100),1,100-(8-level)*30))
                NTC.SetSymptomTrue(character,"sym_fever",NTMB.Deltatime/NT.Deltatime+1)
            end
            -- bleeding from skin
            if level < 7 then
                for type in limbtypes do
                    local bleeding = HF.GetAfflictionStrengthLimb(character,type,"bleeding",0)
                    local desiredBleeding = (7-level)*2
                    if bleeding < desiredBleeding then
                        bleeding = math.min(desiredBleeding,bleeding+NTMB.Deltatime*0.2)
                    end
                    HF.SetAfflictionLimb(character,"bleeding",type,bleeding)
                end
            end
            -- sepsis
            if level < 6 then
                if HF.Chance(NTMB.Deltatime*0.01) then
                    HF.AddAffliction(character,"sepsis",1)
                end
            end
            -- convulsions
            if level < 5 then
                if HF.Chance(NTMB.Deltatime*0.01) then
                    NTC.SetSymptomTrue(character,"triggersym_seizure",2)
                end
            end

            -- no toxicity
        end
    },
    vitamind={
        normalRange={30,100},
        unit="nmol/L",
        foodUnit="%",
        type="vitamin",
        absorptionMultiplier=0.1,
        idleDrainRate=0.01,
        exertDrainRate=0.01,
        func=function(charID,character,level,i) 

            -- at low levels, fractures

            -- TODO

            -- at high levels, dehydration, hypertension, vomiting, decreased appetite, fatigue, weakness, insomnia, slow onset

            -- weakness
            if level > 150 then
                NTC.SetSymptomTrue(character,"sym_weakness",NTMB.Deltatime/NT.Deltatime+1)
            end
            -- vomiting
            if level > 170 then
                if HF.Chance(NTMB.Deltatime*(190-level)*0.001) then
                    NTC.SetSymptomTrue(character,"sym_vomiting",HF.RandomRange(5,10))
                end
            end
        end
    },
    vitamink={
        normalRange={0.2,3.2},
        decimals=2,
        unit="ng/mL",
        foodUnit="%",
        type="vitamin",
        absorptionMultiplier=0.01,
        idleDrainRate=0.0001,
        exertDrainRate=0.0001,
        func=function(charID,character,level,i) 

            -- at low levels, bleeding

            -- bleeding from skin
            if level < 0.2 then
                for type in limbtypes do
                    local bleeding = HF.GetAfflictionStrengthLimb(character,type,"bleeding",0)
                    local desiredBleeding = (0.2-level)*20
                    if bleeding < desiredBleeding then
                        bleeding = math.min(desiredBleeding,bleeding+NTMB.Deltatime*0.2)
                    end
                    HF.SetAfflictionLimb(character,"bleeding",type,bleeding)
                end
            end

            -- no toxicity
        end
    },
}

Timer.Wait(function()

    NT.Afflictions.sym_thirst = {update=function(c,i)
        if c.afflictions.sym_unconsciousness.strength>0 then
            c.afflictions[i].strength=0
        else
            local waterlevel = NTMB.GetNutrientLevel(NTMB.GetCharacterID(c.character),"water",60)
            local sodiumlevel = NTMB.GetNutrientLevel(NTMB.GetCharacterID(c.character),"sodium",140)
            local desiredStrength = (55-waterlevel)*10
                +HF.Clamp((sodiumlevel-150)*2,0,50)
        
            c.afflictions[i].strength = HF.Lerp(c.afflictions[i].strength,desiredStrength,0.5)
        end
    end
    }

    NT.Afflictions.sym_noappetite = {update=function(c,i)
        if c.afflictions.sym_unconsciousness.strength>0 then
            c.afflictions[i].strength=0
        else
            local sodiumlevel = NTMB.GetNutrientLevel(NTMB.GetCharacterID(c.character),"sodium",140)
            local vitaminB12level = NTMB.GetNutrientLevel(NTMB.GetCharacterID(c.character),"vitaminB12",400)
            local vitaminDlevel = NTMB.GetNutrientLevel(NTMB.GetCharacterID(c.character),"vitaminD",65)
            local desiredStrength = 
                HF.Clamp((sodiumlevel-170),0,50)+
                HF.Clamp((120-sodiumlevel),0,50)+
                HF.Clamp((140-vitaminB12level),0,50)+
                HF.Clamp((vitaminDlevel-105),0,50)
        
            c.afflictions[i].strength = HF.Lerp(c.afflictions[i].strength,desiredStrength,0.5)
        end
    end
    }

end,1000)