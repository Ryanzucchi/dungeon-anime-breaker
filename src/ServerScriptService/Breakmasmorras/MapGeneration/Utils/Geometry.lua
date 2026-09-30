local Geometry = {}
function Geometry.part(parent, name, size, cframe, color, material, collidable)
    local part = Instance.new("Part")
    part.Name, part.Size = name, size
    part.CFrame = typeof(cframe) == "Vector3" and CFrame.new(cframe) or cframe
    part.Anchored, part.Color = true, color or Color3.new(1, 1, 1)
    part.Material, part.TopSurface, part.BottomSurface = material or Enum.Material.SmoothPlastic, Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
    part.CanCollide = collidable ~= false
    part.CanTouch, part.CanQuery = false, collidable ~= false
    part.Parent = parent
    return part
end
function Geometry.block(parent, name, size, position, color, material, collidable)
    return Geometry.part(parent, name, size, CFrame.new(position), color, material, collidable)
end
function Geometry.segment(parent, name, startPoint, endPoint, width, thickness, color, material, collidable)
    local delta = endPoint - startPoint
    local length = delta.Magnitude
    if length < 0.1 then return nil end
    local middle = (startPoint + endPoint) * 0.5
    local frame = CFrame.lookAt(middle, endPoint)
    return Geometry.part(parent, name, Vector3.new(width, thickness, length), frame, color, material, collidable)
end
function Geometry.debugBox(parent, name, center, size, color)
    local box = Geometry.block(parent, name, size, center, color, Enum.Material.Neon, false)
    box.Transparency = 0.86
    box.CanQuery = false
    return box
end
return Geometry
