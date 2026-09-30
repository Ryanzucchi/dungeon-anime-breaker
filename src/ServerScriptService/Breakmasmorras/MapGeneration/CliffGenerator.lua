local Geometry = require(script.Parent.Utils.Geometry)
local CliffGenerator = {}
function CliffGenerator.build(parent, region, biome, settings, rng)
    local built = {}
    local radius = region.Radius * 0.88
    local count = settings.CliffSegmentCount
    local function nearOpening(angle)
        for _, opening in ipairs(region.Entrances) do
            local delta = opening.Position - region.Center
            local openingAngle = math.atan2(delta.Z, delta.X)
            if math.abs(math.atan2(math.sin(angle - openingAngle), math.cos(angle - openingAngle))) < math.pi / count * 0.72 then return true end
        end
        for _, opening in ipairs(region.Exits) do
            local delta = opening.Position - region.Center
            local openingAngle = math.atan2(delta.Z, delta.X)
            if math.abs(math.atan2(math.sin(angle - openingAngle), math.cos(angle - openingAngle))) < math.pi / count * 0.72 then return true end
        end
        return false
    end
    for index = 1, count do
        local angle = (index - 1) * math.pi * 2 / count + rng:NextNumber(-0.08, 0.08)
        if not nearOpening(angle) then
        local height = rng:NextNumber(12, 28) * (biome.HeightVariance or 0.3)
        local width = region.Size / count * rng:NextNumber(0.65, 1.05)
        local depth = rng:NextNumber(8, 16)
        local position = region.Center + Vector3.new(math.cos(angle) * radius, -height / 2, math.sin(angle) * radius)
        local chunk = Geometry.block(parent, "CliffFace", Vector3.new(width, height, depth), position, biome.CliffColor or biome.RockColor, Enum.Material.Rock)
        chunk.CFrame = CFrame.new(position) * CFrame.Angles(0, -angle, rng:NextNumber(-0.08, 0.08))
        table.insert(built, chunk)
        if rng:NextNumber() < 0.45 then
            local protrusion = Geometry.block(parent, "CliffProtrusion", Vector3.new(width * 0.38, height * 0.5, depth * 0.75),
                position + Vector3.new(math.cos(angle) * 3, height * 0.25, math.sin(angle) * 3), biome.RockColor, Enum.Material.Basalt)
            table.insert(built, protrusion)
        end
        end
    end
    region.CliffGeometry = built
    return built
end
return CliffGenerator
