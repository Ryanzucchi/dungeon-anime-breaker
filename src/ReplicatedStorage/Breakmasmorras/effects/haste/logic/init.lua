return {
 Skill=function(combat,ctx)
    ctx.State.Haste,ctx.State.HasteUntil=ctx.Skill.Amount or 1.2,ctx.Now+(ctx.Skill.Duration or 4)
    combat:emit(ctx.Config.Visual,ctx.Root.Position,ctx.Color,6)
 end,
 Support=function(combat,ctx)
    ctx.State.Haste,ctx.State.HasteUntil=ctx.Skill.Amount,ctx.Now+ctx.Config.Duration
    combat:emit(ctx.Config.Visual,ctx.MainRoot.Position,ctx.Definition.Color,6)
 end
}