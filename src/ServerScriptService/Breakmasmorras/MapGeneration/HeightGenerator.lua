local HeightGenerator = {}
function HeightGenerator.profile(region, biome, rng)
    local profile = { Base = region.Elevation, Peaks = {}, Ravines = {}, Variation = biome.HeightVariance or 0.3 }
    local count = math.clamp(math.floor(3 + profile.Variation * 6), 3, 9)
    for index = 1, count do
        local angle = rng:NextNumber(0, math.pi * 2)
        local radius = region.Radius * rng:NextNumber(0.52, 0.88)
        local height = rng:NextNumber(4, 8 + profile.Variation * 22)
        table.insert(profile.Peaks, { Offset = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius), Height = height })
        if profile.Variation > 0.6 and index % 3 == 0 then
            table.insert(profile.Ravines, { Offset = Vector3.new(math.cos(angle + 0.5) * radius * 0.82, 0, math.sin(angle + 0.5) * radius * 0.82), Depth = rng:NextNumber(3, 8) })
        end
    end
    region.ElevationProfile = profile
    return profile
end
return HeightGenerator