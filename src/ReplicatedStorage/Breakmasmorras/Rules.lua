local Rules = {}

function Rules.baseId(id)
    return (string.gsub(id, "_shiny$", ""))
end

function Rules.finite(number)
    return type(number) == "number" and number == number and math.abs(number) < math.huge
end

function Rules.damage(base, level, shiny)
    local multiplier = shiny and 1.2 or 1
    return base * (1 + math.max(0, level - 1) * 0.04) * multiplier
end

function Rules.consumeBucket(bucket, now, rate, capacity)
    bucket.tokens = math.min(capacity, bucket.tokens + math.max(0, now - bucket.time) * rate)
    bucket.time = now
    if bucket.tokens < 1 then return false end
    bucket.tokens = bucket.tokens - 1
    return true
end

function Rules.addXP(unit, amount, maxLevel, xpForLevel)
    unit.XP = unit.XP + math.max(0, amount)
    while unit.Level < maxLevel and unit.XP >= xpForLevel(unit.Level) do
        unit.XP = unit.XP - xpForLevel(unit.Level)
        unit.Level = unit.Level + 1
    end
    if unit.Level >= maxLevel then unit.XP = 0 end
end

return Rules
