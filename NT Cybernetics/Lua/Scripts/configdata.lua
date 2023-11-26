NTCyb.ConfigData = {
    NTCyb_header1 = {name=NTCyb.Name,type="category"},

    NTCyb_waterDamage = {name="cybernetic water damage",default=1,range={0,100},type="float", difficultyCharacteristics={multiplier=0.5,max=1}}
}
NTConfig.AddConfigOptions(NTCyb)