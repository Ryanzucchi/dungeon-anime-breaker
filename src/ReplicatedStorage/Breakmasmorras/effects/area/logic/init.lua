return { Skill=function(combat,ctx)
    combat:area(ctx.Player,ctx.Center,ctx.Skill.Radius,ctx.Damage,ctx.Skill)
    combat:emit(ctx.Config.Visual,ctx.Center,ctx.Color,ctx.Skill.Radius)
end }