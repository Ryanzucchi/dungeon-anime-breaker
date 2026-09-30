return { Damage=function(amount,skill,enemy,now,config)
    if skill.Effect=="pierce" and (enemy.StunUntil>now or enemy.SlowUntil>now) then return amount*config.DamageMultiplier end
    return amount
end }