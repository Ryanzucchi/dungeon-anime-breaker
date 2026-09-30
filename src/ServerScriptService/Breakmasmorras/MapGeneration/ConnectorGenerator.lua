local Geometry = require(script.Parent.Utils.Geometry)
local PathGenerator = require(script.Parent.PathGenerator)
local Seed = require(script.Parent.Utils.Seed)
local ConnectorGenerator = {}
local types = { "Path", "Bridge", "MountainPass", "Canyon", "Tunnel", "Gate", "RuinedGate" }
function ConnectorGenerator.build(parent, edge, regions, theme, settings, seed)
    local from, to = regions[edge.From], regions[edge.To]
    if not from or not to then return nil end
    local delta = to.Center - from.Center
    local planar = Vector3.new(delta.X, 0, delta.Z)
    if planar.Magnitude < 0.1 then return nil end
    local direction = planar.Unit
    local startPoint = from.Center + direction * math.max(12, from.Radius * 0.62) + Vector3.new(0, 0.3, 0)
    local endPoint = to.Center - direction * math.max(12, to.Radius * 0.62) + Vector3.new(0, 0.3, 0)
    local rng = Seed.random(seed, "connector", edge.From .. ":" .. edge.To)
    local connectorType = edge.WaterCrossing and "RiverCrossing" or (math.abs(to.Elevation - from.Elevation) > 7 and "Stairs" or types[rng:NextInteger(1, #types)])
    if edge.Optional then connectorType = "SecretPassage" end
    local path = PathGenerator.points(startPoint, endPoint, settings.ConnectorWidth, math.min(18, delta.Magnitude * 0.08), rng, 5)
    local biome = theme.Biomes[from.Biome]
    local pathTheme = { PathColor = biome.PathColor }
    local material = Enum.Material.Sand
    if connectorType == "Bridge" or connectorType == "RiverCrossing" then material, pathTheme.PathColor = Enum.Material.WoodPlanks, theme.Palette.Ruins end
    if connectorType == "RuinedGate" or connectorType == "Gate" then material, pathTheme.PathColor = Enum.Material.Slate, theme.Palette.Ruins end
    local parts = {}
    if connectorType == "Stairs" then
        local stepCount = 8
        for index = 1, stepCount do
            local t = (index - 0.5) / stepCount
            local position = startPoint:Lerp(endPoint, t)
            local previous = startPoint:Lerp(endPoint, (index - 1) / stepCount)
            local following = startPoint:Lerp(endPoint, index / stepCount)
            local forward = Vector3.new(position.X - previous.X, 0, position.Z - previous.Z)
            local nextForward = Vector3.new(following.X - position.X, 0, following.Z - position.Z)
            local length = math.max(4, forward.Magnitude + nextForward.Magnitude + 0.5)
            local frame = CFrame.lookAt(position + Vector3.new(0, 0.1, 0), position + Vector3.new(forward.X, 0, forward.Z))
            table.insert(parts, Geometry.part(parent, "StairTread", Vector3.new(settings.ConnectorWidth, 0.8, length), frame, pathTheme.PathColor, Enum.Material.Slate, true))
        end
    else
        parts = PathGenerator.build(parent, path, pathTheme, connectorType .. "Path", material, true)
    end
    if connectorType == "Bridge" or connectorType == "RiverCrossing" or connectorType == "Stairs" then
        for side = -1, 1, 2 do
            local offset = Vector3.new(-direction.Z, 0, direction.X) * side * settings.ConnectorWidth * 0.55
            Geometry.segment(parent, connectorType .. "Rail", startPoint + offset + Vector3.new(0, 1.1, 0),
                endPoint + offset + Vector3.new(0, 1.1, 0), 1.2, 1.5, theme.Palette.Rock, Enum.Material.Rock, false)
        end
    end
    local perpendicular = Vector3.new(-direction.Z, 0, direction.X)
    if connectorType == "Tunnel" then
        for side = -1, 1, 2 do
            Geometry.segment(parent, "TunnelWall", startPoint + perpendicular * side * settings.ConnectorWidth * 0.55 + Vector3.new(0, 5, 0),
                endPoint + perpendicular * side * settings.ConnectorWidth * 0.55 + Vector3.new(0, 5, 0), 1.5, 10, theme.Palette.Rock, Enum.Material.Rock, true)
        end
        Geometry.segment(parent, "TunnelRoof", startPoint + Vector3.new(0, 10, 0), endPoint + Vector3.new(0, 10, 0),
            settings.ConnectorWidth + 2, 2, theme.Palette.Rock, Enum.Material.Rock, true)
    elseif connectorType == "Gate" or connectorType == "RuinedGate" then
        for side = -1, 1, 2 do
            Geometry.block(parent, "GatePillar", Vector3.new(4, 13, 4), startPoint + perpendicular * side * settings.ConnectorWidth * 0.55 + Vector3.new(0, 6.5, 0), theme.Palette.Ruins, Enum.Material.Rock, true)
        end
        Geometry.block(parent, "GateLintel", Vector3.new(settings.ConnectorWidth + 7, 3, 5), startPoint + Vector3.new(0, 13, 0), theme.Palette.Ruins, Enum.Material.Rock, true)
    elseif connectorType == "Canyon" or connectorType == "MountainPass" then
        for side = -1, 1, 2 do
            Geometry.segment(parent, "ConnectorCliff", startPoint + perpendicular * side * (settings.ConnectorWidth + 7) + Vector3.new(0, 7, 0),
                endPoint + perpendicular * side * (settings.ConnectorWidth + 7) + Vector3.new(0, 7, 0), 8, 14, theme.Palette.Cliff, Enum.Material.Rock, true)
        end
    end
    return { Id = edge.From .. "->" .. edge.To, Type = connectorType, Path = path, Parts = parts,
        StartPosition = startPoint, EndPosition = endPoint, StartElevation = from.Elevation, EndElevation = to.Elevation,
        Width = settings.ConnectorWidth, Theme = theme.Id, WaterCrossing = edge.WaterCrossing == true }
end
return ConnectorGenerator
