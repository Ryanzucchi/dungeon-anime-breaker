return { Skill=function(combat,ctx)
    combat:line(ctx.Player,ctx.Root.Position,ctx.Direction,ctx.Skill.Range,ctx.Skill.Radius,ctx.Damage,ctx.Skill,ctx.Color)
end }