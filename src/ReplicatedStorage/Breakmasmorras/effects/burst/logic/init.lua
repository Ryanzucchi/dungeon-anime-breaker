local function alive(combat,ctx)
    local humanoid=ctx.Model:FindFirstChildOfClass("Humanoid")
    return combat.States[ctx.Player]==ctx.State and ctx.Player.Character==ctx.Model and humanoid and humanoid.Health>0
end
return { Skill=function(combat,ctx)
    local center=ctx.Root.Position+ctx.Direction*ctx.Skill.Range*0.5
    for hit=1,ctx.Skill.Hits do
        task.delay((hit-1)*ctx.Config.HitInterval,function()
            if alive(combat,ctx) then
                combat:area(ctx.Player,center,ctx.Skill.Radius,ctx.Damage,ctx.Skill)
                combat:emit(ctx.Config.Visual,center,ctx.Color,ctx.Skill.Radius)
            end
        end)
    end
end }