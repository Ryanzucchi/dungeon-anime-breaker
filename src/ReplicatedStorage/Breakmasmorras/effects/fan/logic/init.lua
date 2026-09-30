return { Skill=function(combat,ctx)
    for _,angle in ipairs(ctx.Config.Angles) do
        local direction=CFrame.fromAxisAngle(Vector3.yAxis,angle):VectorToWorldSpace(ctx.Direction)
        combat:line(ctx.Player,ctx.Root.Position,direction,ctx.Skill.Range,ctx.Skill.Radius,ctx.Damage/ctx.Config.DamageDivision,ctx.Skill,ctx.Color)
    end
end }