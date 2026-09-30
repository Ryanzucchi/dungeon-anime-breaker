local Placement = {}

local function distanceToSegment(point, startPoint, endPoint)
	local delta, offset = endPoint - startPoint, point - startPoint
	local lengthSquared = delta.X*delta.X + delta.Z*delta.Z
	if lengthSquared < 0.01 then return Vector3.new(offset.X,0,offset.Z).Magnitude end
	local t = math.clamp((offset.X*delta.X + offset.Z*delta.Z) / lengthSquared, 0, 1)
	local closest = startPoint + delta*t
	return Vector3.new(point.X-closest.X,0,point.Z-closest.Z).Magnitude
end

function Placement.isClear(region, position, clearance, ignoreEncounter)
	clearance = clearance or 5
	if not ignoreEncounter and not region.Optional and region.EncounterArea then
		local delta = position - region.EncounterArea.Center
		if Vector3.new(delta.X,0,delta.Z).Magnitude < region.EncounterArea.Radius + clearance then return false end
	end
	for _, opening in ipairs(region.Entrances) do
		if distanceToSegment(position, region.Center, opening.Position) < clearance + 3 then return false end
	end
	for _, opening in ipairs(region.Exits) do
		if distanceToSegment(position, region.Center, opening.Position) < clearance + 3 then return false end
	end
	return true
end

return Placement
