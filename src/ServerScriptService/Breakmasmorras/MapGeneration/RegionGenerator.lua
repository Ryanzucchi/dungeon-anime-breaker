local EncounterGenerator = require(script.Parent.EncounterGenerator)
local RoomLayouts = require(script.Parent.RoomLayouts)
local Seed = require(script.Parent.Utils.Seed)
local RegionGenerator = {}
function RegionGenerator.generate(parent, node, phase, neighbors, theme, settings)
    local rng = Seed.random(node.Seed, "region-metadata")
    local sizeRange = settings.RegionSizes[node.Size] or settings.RegionSizes.Medium
    local size = rng:NextInteger(sizeRange.Min, sizeRange.Max)
    local region = { Id = node.Id, Type = node.Type, Center = node.Position, Elevation = node.Elevation, Height = node.Elevation,
        Size = size, Radius = size * 0.5, Biome = node.Biome, Seed = node.Seed, Difficulty = node.Difficulty,
        Importance = node.Importance, Optional = node.Optional, Entrances = {}, Exits = {}, DecorationZones = {},
        PhaseIndex = node.PhaseIndex, RoomInPhase = ((node.MainIndex or 1) - 1) % 5 + 1,
        Variant = rng:NextInteger(1, #RoomLayouts), PhaseId = node.PhaseId, MainIndex = node.MainIndex }
    region.LayoutName = RoomLayouts[region.Variant]
    local biome = assert(theme.Biomes[region.Biome], "Biome ausente no ThemePack " .. theme.Id .. ": " .. tostring(region.Biome))
    local folder = Instance.new("Folder")
    folder.Name, folder.Parent = "Region_" .. node.Id, parent
    region.Folder = folder
    for _, layer in ipairs({ "GameplayGeometry", "VisualGeometry", "Decoration", "Debug", "Base", "Terrain", "Path", "Detail", "Vegetation" }) do
        local child = Instance.new("Folder")
        child.Name, child.Parent = layer, folder
        region[layer] = child
    end
    for _, neighbor in ipairs(neighbors or {}) do
        local offset = neighbor.Position - node.Position
        local planar = Vector3.new(offset.X, 0, offset.Z)
        if planar.Magnitude > 0 then
            local edgePoint = node.Position + planar.Unit * region.Radius * 0.72 + Vector3.new(0, 0.25, 0)
            local opening = { Position = edgePoint, To = neighbor.Id, Direction = planar.Unit, Elevation = neighbor.Elevation }
            if neighbor.MainIndex and neighbor.MainIndex < (node.MainIndex or math.huge) then
                table.insert(region.Entrances, opening)
            else
                table.insert(region.Exits, opening)
            end
        end
    end
    region.WalkableArea = { Center = region.Center, Radius = region.Radius * 0.76 }
    region.ReservedAreas = {
        { Kind = "Path", Center = region.Center, Radius = settings.PathWidth * 1.6 },
        { Kind = "Encounter", Center = region.Center, Radius = region.Radius * 0.36 },
    }
    region.Spawn = region.Center + Vector3.new(0, 4, region.Radius * 0.48)
    region.Enemies = EncounterGenerator.generate(region, phase, rng, settings, node.MainIndex or 0)
    region.EnemyCount = #region.Enemies
    region.EncounterArea = { Center = region.Center, Radius = region.Radius * 0.56 }
    table.insert(region.ReservedAreas, { Kind = "Encounter", Center = region.Center, Radius = region.EncounterArea.Radius })
    for _, opening in ipairs(region.Entrances) do table.insert(region.ReservedAreas, { Kind = "Path", Start = region.Center, Finish = opening.Position, Radius = settings.PathWidth * 0.65 }) end
    for _, opening in ipairs(region.Exits) do table.insert(region.ReservedAreas, { Kind = "Path", Start = region.Center, Finish = opening.Position, Radius = settings.PathWidth * 0.65 }) end
    region.SpawnZones = {
        region.Center + Vector3.new(-region.Radius * 0.45, 2, -region.Radius * 0.2),
        region.Center + Vector3.new(region.Radius * 0.45, 2, region.Radius * 0.2),
    }
    region.LandmarkSlots = { region.Center + Vector3.new(region.Radius * 0.64, 0, -region.Radius * 0.58) }
    region.DecorationZones = {
        { Center = region.Center + Vector3.new(region.Radius * 0.78, 0, region.Radius * 0.38), Radius = region.Radius * 0.18 },
        { Center = region.Center + Vector3.new(-region.Radius * 0.75, 0, -region.Radius * 0.34), Radius = region.Radius * 0.2 },
    }
    region.ThemeId, region.BiomeConfig = theme.Id, biome
    return region
end
return RegionGenerator
