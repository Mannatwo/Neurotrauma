NTMB.ConfigData = {
    NTMB_header1 = {name=NTMB.Name,type="category"},

    NTMB_metabolismSpeed = {name="metabolism speed",default=1,range={0,100},type="float", difficultyCharacteristics={max=5},description="how quickly nutrients get used up"},
    NTMB_digestionSpeed = {name="digestion speed",default=1,range={0,100},type="float",description="how quickly the contents of the stomach get broken down and enter the bloodstream"},
    NTMB_hungerSpeed = {name="hunger speed",default=1,range={0,100},type="float",description="how quickly you get hungry on an empty stomach or malnutrition"},
    NTMB_rateNormalization = {name="rate normalization",default=1,range={0,100},type="float",description="how much nutrition values tend to stay inside normal bounds. The higher the value, the harder it is to completely run out of a nutrient, and the faster nutrients you have too many of get used."},
    NTMB_exertionImpact = {name="exertion impact",default=1,range={0,100},type="float", difficultyCharacteristics={max=5},description="how much moving around, climbing ladder or swimming will affect drain rate of nutrients"},

    NTMB_crewAIMetabolsim = {name="crew AI has metabolism",default=false,type="bool",description="if this is turned on, the chef will have to babysit the crewmate AIs"},
    NTMB_forceFeeding = {name="allow force feeding",default=true,type="bool",description="if people should be able to forcibly feed other people food via the health interface"},
    NTMB_taintedWater = {name="tainted water",default=true,type="bool",description="if turned off, ocean water is considered safe to drink"},
}
NTConfig.AddConfigOptions(NTMB)