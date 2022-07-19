
-- hopefully this stops bots from doing any rescuing at all.
-- and also hopefully my assumption that this very specific thing
-- about bots is what is causing them to eat frames is correct.

if NT.Config.disableBotAlgorithms then
    Hook.HookMethod("Barotrauma.AIObjectiveRescueAll", "IsValidTarget", function (instance, ptable)
        return false
    end, Hook.HookMethodType.Before)    
end


