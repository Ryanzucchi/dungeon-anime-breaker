local Geometry = require(script.Parent.Utils.Geometry)
local TerrainGenerator = {}
function TerrainGenerator.build(parent, region, biome, settings, rng)
    local top, radius = region.Elevation, region.Radius
    local material = biome.GroundMaterial or Enum.Material.Grass
    local patches = {}
    local core = Geometry.block(region.Base, "GroundBase", Vector3.new(radius * 1.08, settings.FloorThickness, radius * 1.08),
        region.Center - Vector3.new(0, settings.FloorThickness / 2, 0), biome.GroundColor, material)
    table.insert(patches, core)
    for index = 1, 7 do
        local angle = (index - 1) * math.pi * 2 / 7 + rng:NextNumber(-0.12, 0.12)
        local distance = radius * rng:NextNumber(0.48, 0.66)
        local width, depth = radius * rng:NextNumber(0.56, 0.78), radius * rng:NextNumber(0.48, 0.73)
        local position = region.Center + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
        local patch = Geometry.block(region.Terrain, "TerrainPatch", Vector3.new(width, settings.FloorThickness, depth),
            position - Vector3.new(0, settings.FloorThickness / 2, 0), biome.GroundColor, material)
        table.insert(patches, patch)
    end
    region.GroundShape = { CenterSize = radius * 1.08, Patches = patches, Shape = "organic_cluster" }
    local visual = region.VisualGeometry
    for _, peak in ipairs(region.ElevationProfile.Peaks) do
        if peak.Height >= 10 and peak.Offset.Magnitude > radius * 0.58 then
            local height = math.min(peak.Height, 24)
            local platformPosition = region.Center + peak.Offset + Vector3.new(0, height, 0)
            Geometry.block(visual, "MesaTop", Vector3.new(18, 2, 18), platformPosition, biome.GroundColor, material)
            Geometry.block(visual, "MesaCliff", Vector3.new(17, height * 2, 17),
                platformPosition - Vector3.new(0, height, 0), biome.CliffColor, Enum.Material.Rock)
            local stepCount = 5
            for step = 1, stepCount do
                local stepY = 0.75 + (height - 1.5) * ((step - 1) / (stepCount - 1))
                Geometry.block(region.Path, "MesaStair", Vector3.new(8, 1.5, 4),
                    region.Center + peak.Offset + Vector3.new(-12 + step * 2, stepY, 8 + step * 2), biome.PathColor, Enum.Material.Slate)
            end
        end
    end
    for _, ravine in ipairs(region.ElevationProfile.Ravines) do
        local position = region.Center + ravine.Offset
        local dark = Geometry.block(visual, "RavineBed", Vector3.new(18, 0.5, 32),
            position - Vector3.new(0, ravine.Depth, 0), biome.CliffColor, Enum.Material.Basalt, false)
        dark.Transparency = 0.12
    end
    return patches
end
return TerrainGenerator
