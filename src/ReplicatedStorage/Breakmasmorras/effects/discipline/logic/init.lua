return {
    Combo=function(state) state.SealReady=true end,
    Empower=function(state,slot,config)
        if state.SealReady then
            for _,triggerSlot in ipairs(config.TriggerSlots) do
                if slot==triggerSlot then
                    state.SealReady=false
                    return config.DamageMultiplier
                end
            end
        end
        return 1
    end
}