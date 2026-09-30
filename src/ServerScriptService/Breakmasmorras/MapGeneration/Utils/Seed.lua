local Seed = {}
function Seed.derive(seed, label, index)
    local value = math.abs(math.floor(tonumber(seed) or 1)) % 2147483647
    local text = tostring(label or "") .. ":" .. tostring(index or 0)
    for position = 1, #text do
        value = (value * 31 + string.byte(text, position)) % 2147483647
    end
    if value == 0 then value = 1 end
    return value
end
function Seed.random(seed, label, index)
    return Random.new(Seed.derive(seed, label, index))
end
return Seed