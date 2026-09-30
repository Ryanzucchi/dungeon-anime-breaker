local WeightedRandom = {}
function WeightedRandom.pick(rng, entries)
    local total = 0
    for _, entry in ipairs(entries) do total = total + math.max(0, entry.Weight or 0) end
    if total <= 0 then return entries[1] end
    local selected = rng:NextNumber(0, total)
    for _, entry in ipairs(entries) do
        selected = selected - math.max(0, entry.Weight or 0)
        if selected <= 0 then return entry end
    end
    return entries[#entries]
end
return WeightedRandom