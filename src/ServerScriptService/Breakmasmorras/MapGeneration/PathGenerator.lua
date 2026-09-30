local Geometry = require(script.Parent.Utils.Geometry)
local PathGenerator = {}
function PathGenerator.points(startPoint, endPoint, width, curvature, rng, segments)
    local delta = endPoint - startPoint
    local planar = Vector3.new(delta.X, 0, delta.Z)
    local perpendicular = planar.Magnitude > 0 and Vector3.new(-planar.Unit.Z, 0, planar.Unit.X) or Vector3.new(1, 0, 0)
    local control = (startPoint + endPoint) * 0.5 + perpendicular * ((rng:NextNumber() * 2 - 1) * curvature)
    local result = {}
    for index = 0, segments do
        local t = index / segments
        local point = startPoint * ((1 - t) * (1 - t)) + control * (2 * (1 - t) * t) + endPoint * (t * t)
        table.insert(result, point)
    end
    return { Points = result, Width = width, Start = startPoint, Finish = endPoint }
end
function PathGenerator.build(parent, path, biome, name, material, collidable)
    local segments = {}
    for index = 1, #path.Points - 1 do
        local a, b = path.Points[index], path.Points[index + 1]
        table.insert(segments, Geometry.segment(parent, name or "PathSegment", a, b, path.Width, 0.7,
            biome.PathColor, material or Enum.Material.Sand, collidable ~= false))
    end
    return segments
end
return PathGenerator