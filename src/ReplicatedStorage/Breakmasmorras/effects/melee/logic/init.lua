return { Skill=function(combat,ctx)
    local center=ctx.Root.Position+ctx.Direction*ctx.Skill.Range*0.5
    combat:area(ctx.Player,center,ctx.Skill.Radius,ctx.Damage,ctx.Skill)
    combat:emit(ctx.Config.Visual,center,ctx.Color,ctx.Skill.Radius)
end }