local function alive(combat,ctx)
    local humanoid=ctx.Model:FindFirstChildOfClass("Humanoid")
    return combat.States[ctx.Player]==ctx.State and ctx.Player.Character==ctx.Model and humanoid and humanoid.Health>0
end
return { Skill=function(combat,ctx)
    combat:emit(ctx.Config.TelegraphVisual,ctx.Center,ctx.Color,ctx.Skill.Radius,nil,ctx.Config.Delay)
    task.delay(ctx.Config.Delay,function()
        if not alive(combat,ctx) then return end
        combat:area(ctx.Player,ctx.Center,ctx.Skill.Radius,ctx.Damage,ctx.Skill)
        combat:emit(ctx.Config.ImpactVisual,ctx.Center,ctx.Color,ctx.Skill.Radius,nil,0.55,ctx.Skill.ImpactLevel or 3,ctx.ImpactProfile)
    end)
    if ctx.Skill.Haste then ctx.State.Haste,ctx.State.HasteUntil=ctx.Skill.Haste,ctx.Now+ctx.Config.HasteDuration end
end }