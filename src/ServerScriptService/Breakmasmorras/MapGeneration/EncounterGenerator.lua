local EncounterGenerator = {}
function EncounterGenerator.generate(region, phase, rng, settings, roomNumber)
    if region.Type == "Rest" or region.Type == "Vista" or region.Type == "Start" then return {} end
    local boss = region.Type == "Boss" or roomNumber == 25
    local count = boss and 1 or rng:NextInteger(phase.MinEnemies, math.min(phase.MaxEnemies, settings.MaxEnemiesPerArea))
    local encounters = {}
    for index = 1, count do
        local angle = rng:NextNumber(0, math.pi * 2)
        local distance = region.Radius * rng:NextNumber(0.18, 0.48)
        table.insert(encounters, region.Center + Vector3.new(math.cos(angle) * distance, 4, math.sin(angle) * distance))
    end
    region.EncounterArea = { Center = region.Center, Radius = region.Radius * 0.56 }
    region.SpawnZones = {
        region.Center + Vector3.new(-region.Radius * 0.45, 2, -region.Radius * 0.2),
        region.Center + Vector3.new(region.Radius * 0.45, 2, region.Radius * 0.2),
    }
    return encounters
end
return EncounterGenerator
