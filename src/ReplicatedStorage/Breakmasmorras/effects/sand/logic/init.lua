return { Update=function(combat,state,root,definition,now,config)
    if now>=state.NextSand and now-state.LastCombat<5 then
        state.NextSand=now+config.Cooldown
        state.Shield=math.min(100,state.Shield+config.Shield)
        state.ShieldUntil=now+config.Duration
        combat:emit(config.Visual,root.Position,definition.Color,config.Shield/5)
    end
end }