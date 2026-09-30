return {
 Skill=function(combat,ctx)
    ctx.State.Shield=math.min(100,ctx.State.Shield+ctx.Skill.Shield)
    ctx.State.ShieldUntil=ctx.Now+ctx.Config.Duration
    combat:emit(ctx.Config.Visual,ctx.Root.Position,ctx.Color,5)
 end,
 Support=function(combat,ctx)
    ctx.State.Shield=math.min(100,ctx.State.Shield+ctx.Amount)
    ctx.State.ShieldUntil=ctx.Now+6
    combat:emit(ctx.Config.Visual,ctx.MainRoot.Position,ctx.Definition.Color,5)
 end
}