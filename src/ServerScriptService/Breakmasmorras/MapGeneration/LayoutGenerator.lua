local Geometry = require(script.Parent.Utils.Geometry)
local Seed = require(script.Parent.Utils.Seed)
local Placement = require(script.Parent.Utils.Placement)
local Generator = {}

local patterns = {
	{ {-.62,-.18}, {-.28,.64}, {.42,.56}, {.68,-.12} },
	{ {-.68,0}, {-.42,.12}, {.42,-.12}, {.68,0} },
	{ {-.58,-.48}, {-.58,.48}, {.58,-.48}, {.58,.48} },
	{ {-.68,-.42}, {-.48,-.42}, {.48,.42}, {.68,.42} },
	{ {-.62,-.62}, {-.62,.62}, {.62,-.62}, {.62,.62} },
	{ {-.66,-.5}, {-.28,.5}, {.22,-.5}, {.66,.5} },
	{ {-.66,-.62}, {-.66,.62}, {.66,-.62}, {.66,.62}, {-.34,0}, {.34,0} },
	{ {-.54,-.54}, {-.54,.54}, {.54,-.54}, {.54,.54}, {0,-.72}, {0,.72} },
	{ {-.66,-.25}, {-.22,.25}, {.22,-.25}, {.66,.25} },
	{ {-.62,-.62}, {-.62,.62}, {.62,-.62}, {.62,.62} },
	{ {-.7,-.28}, {-.7,.28}, {.7,-.28}, {.7,.28} },
	{ {-.7,-.5}, {-.7,.5}, {.7,-.5}, {.7,.5} },
	{ {-.64,-.3}, {-.3,-.64}, {.3,.64}, {.64,.3}, {-.64,.3}, {.64,-.3} },
	{ {-.7,-.56}, {-.42,.56}, {.42,-.56}, {.7,.56} },
	{ {-.62,-.62}, {-.62,.62}, {.62,-.62}, {.62,.62}, {0,-.7}, {0,.7} },
	{ {-.64,-.5}, {-.64,.5}, {.64,-.5}, {.64,.5} },
	{ {-.68,-.58}, {-.42,.58}, {-.14,-.58}, {.14,.58}, {.42,-.58}, {.68,.58} },
	{ {-.66,-.5}, {-.66,.5}, {.66,-.5}, {.66,.5}, {0,-.68}, {0,.68} },
	{ {-.7,-.3}, {-.35,.3}, {0,-.3}, {.35,.3}, {.7,-.3} },
	{ {-.64,-.6}, {-.64,.6}, {.64,-.6}, {.64,.6}, {-.25,0}, {.25,0} },
	{ {-.62,-.62}, {-.42,.4}, {-.12,-.12}, {.2,.2}, {.48,-.48}, {.68,.68} },
	{ {-.68,-.42}, {-.68,.42}, {0,-.56}, {0,.56}, {.68,-.42}, {.68,.42} },
	{ {-.62,-.62}, {-.62,.62}, {.62,-.62}, {.62,.62}, {0,-.72}, {0,.72} },
	{ {-.62,-.55}, {-.62,.55}, {-.2,-.68}, {.2,.68}, {.62,-.55}, {.62,.55} },
}

local function distanceToSegment(point, startPoint, endPoint)
	local delta, offset = endPoint - startPoint, point - startPoint
	local lengthSquared = delta.X*delta.X + delta.Z*delta.Z
	if lengthSquared < 0.01 then return Vector3.new(offset.X,0,offset.Z).Magnitude end
	local t = math.clamp((offset.X*delta.X + offset.Z*delta.Z) / lengthSquared, 0, 1)
	local closest = startPoint + delta*t
	return Vector3.new(point.X-closest.X,0,point.Z-closest.Z).Magnitude
end

local function clearOfReservations(position, region, clearance)
	return Placement.isClear(region, position, clearance)
end

function Generator.build(region, theme)
	local rng = Seed.random(region.Seed, "layout", region.Variant)
	local radius, variant = region.Radius, region.Variant
	local color = region.BiomeConfig.RockColor
	local points = patterns[variant]
	local made = 0
	for index, point in ipairs(points) do
		local position = region.Center + Vector3.new(point[1]*radius, 0, point[2]*radius)
		if clearOfReservations(position, region, 10) then
			local width, depth = rng:NextInteger(5, 10), rng:NextInteger(5, 10)
			local height = rng:NextInteger(4, 11)
			local name = (variant == 5 or variant == 10 or variant == 18) and "Altar" or "LayoutFeature"
			local part = Geometry.block(region.GameplayGeometry, name, Vector3.new(width, height, depth),
				position + Vector3.new(0, height/2, 0), color, variant % 4 == 0 and Enum.Material.Marble or Enum.Material.Rock, true)
			part:SetAttribute("LayoutVariant", variant)
			part:SetAttribute("LayoutFeatureIndex", index)
			made += 1
		end
	end
	return made
end

return Generator
