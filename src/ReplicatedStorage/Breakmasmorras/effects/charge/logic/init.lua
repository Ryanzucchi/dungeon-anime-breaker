return { Skill=function(combat,ctx)
    combat:line(ctx.Player,ctx.Root.Position,ctx.Direction,ctx.Skill.Range,ctx.Skill.Radius,ctx.Damage,ctx.Skill,ctx.Color)
    combat:move(ctx.Player,ctx.State,ctx.Direction,ctx.Skill.Range,false)
end }