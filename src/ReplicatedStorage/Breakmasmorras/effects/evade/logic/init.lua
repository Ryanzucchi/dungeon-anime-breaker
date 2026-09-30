return {
    Skill=function(combat,ctx)
        combat:move(ctx.Player,ctx.State,ctx.Direction,ctx.Skill.Range,ctx.Config.Invulnerability)
        combat:emit(ctx.Config.Visual,ctx.Root.Position,ctx.Color,4)
    end,
    Dash=function(combat,ctx)
        local rgb=ctx.Config.Color
        combat:move(ctx.Player,ctx.State,ctx.Direction,ctx.Config.Distance,ctx.Config.Invulnerability)
        combat:emit(ctx.Config.Visual,ctx.Root.Position,Color3.fromRGB(rgb[1],rgb[2],rgb[3]),3)
    end
}