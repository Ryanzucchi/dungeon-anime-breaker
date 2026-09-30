return {
 Skill=function(combat,ctx)
    combat:area(ctx.Player,ctx.Center,ctx.Skill.Radius,ctx.Damage,ctx.Skill)
    combat:emit(ctx.Config.Visual,ctx.Center,ctx.Color,ctx.Skill.Radius)
 end,
 Support=function(combat,ctx)
    for _,enemy in ipairs(combat.Enemies) do
        if enemy.Model.Parent and enemy.Humanoid.Health>0
            and (enemy.Root.Position-ctx.MainRoot.Position).Magnitude<=ctx.Skill.Radius then
            enemy.StunUntil=math.max(enemy.StunUntil,ctx.Now+(enemy.Boss and ctx.Config.BossDuration or ctx.Config.Duration))
        end
    end
    combat:emit(ctx.Config.Visual,ctx.MainRoot.Position,ctx.Definition.Color,ctx.Skill.Radius)
 end
}