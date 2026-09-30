local SpatialHash = {}
SpatialHash.__index = SpatialHash
function SpatialHash.new(cellSize)
    return setmetatable({ CellSize = cellSize or 24, Cells = {} }, SpatialHash)
end
function SpatialHash:key(point)
    return string.format("%d:%d", math.floor(point.X / self.CellSize), math.floor(point.Z / self.CellSize))
end
function SpatialHash:insert(point, value)
    local key = self:key(point)
    self.Cells[key] = self.Cells[key] or {}
    table.insert(self.Cells[key], { Point = point, Value = value })
end
function SpatialHash:near(point, radius)
    local found = {}
    local range = math.ceil(radius / self.CellSize)
    local cx, cz = math.floor(point.X / self.CellSize), math.floor(point.Z / self.CellSize)
    for x = cx - range, cx + range do
        for z = cz - range, cz + range do
            for _, item in ipairs(self.Cells[string.format("%d:%d", x, z)] or {}) do
                if (item.Point - point).Magnitude <= radius then table.insert(found, item.Value) end
            end
        end
    end
    return found
end
return SpatialHash