NTMB.CI = {} -- campaign interface

function NTMB.CI.Set(identifier,data)
    local cData = NTMB.CI.GetCampaignData()
    if not cData then return end
    cData.SetValue(identifier,data)
end

function NTMB.CI.Get(identifier, defaultvalue)
    local cData = NTMB.CI.GetCampaignData()
    if not cData then return defaultvalue end
    local str = cData.GetString(identifier)
    if not str then return defaultvalue end
    return str
end

function NTMB.CI.GetInteger(identifier, defaultvalue)
    local cData = NTMB.CI.GetCampaignData()
    if not cData then return defaultvalue end
    local int = cData.GetInt(identifier)
    if not int then return defaultvalue end
    return int
end

function NTMB.CI.GetCampaignData()
    local session = Game.GameSession
    if not session then return nil end
    local campaign = session.campaign
    if not campaign then return nil end
    local data = campaign.CampaignMetadata
    if not data then return nil end
    return data
end