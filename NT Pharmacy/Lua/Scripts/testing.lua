
-- set the below variable to true to enable debug and testing features
NTP.TestingEnabled = false

Hook.Add('chatMessage', 'NTP.testing', function(msg, client)
    
    if(msg=="ntp1") then
        if not NTP.TestingEnabled then return end
        -- insert testing stuff here
        

        return true
    end
end)