local Geometry = require(script.Parent.Utils.Geometry)
local Seed = require(script.Parent.Utils.Seed)
local Placement = require(script.Parent.Utils.Placement)
local Generator = {}
function Generator.build(region, theme, settings)
	local rng = Seed.random(region.Seed, "vegetation")
	local density = region.BiomeConfig.VegetationDensity or 0
	local variants = theme.Props.Vegetation or { "SmallTree", "Bush" }
	local groundCover = theme.VegetationRules.GroundCover or {}
	local count = math.floor(9 * density * rng:NextNumber(0.65, 1.15))
	for index = 1, count do
		local pos
		for _ = 1, 8 do
			local angle = rng:NextNumber(0, math.pi*2)
			local radius = rng:NextNumber(region.Radius*0.62, region.Radius*0.92)
			local candidate = region.Center + Vector3.new(math.cos(angle)*radius, 0, math.sin(angle)*radius)
			if Placement.isClear(region, candidate, 5) then pos = candidate break end
		end
		if not pos then continue end
		local variant = variants[rng:NextInteger(1, #variants)]
		if table.find(groundCover, variant) then
			local height = rng:NextNumber(1, 3.5)
			Geometry.block(region.Vegetation, variant, Vector3.new(1.2, height, 1.2), pos + Vector3.new(0,height/2,0), region.BiomeConfig.VegetationColor, Enum.Material.Grass, false)
		else
			local height = rng:NextNumber(5, 11)
			Geometry.block(region.Vegetation, variant .. "Trunk", Vector3.new(1.5, height, 1.5), pos + Vector3.new(0,height/2,0), theme.Palette.Rock, Enum.Material.Wood, false)
			local canopySize = variant == "Bush" and height*0.75 or height*0.8
			Geometry.block(region.Vegetation, variant .. "Canopy", Vector3.new(canopySize, height*0.7, canopySize), pos + Vector3.new(0,height*0.9,0), region.BiomeConfig.VegetationColor, Enum.Material.Grass, false)
		end
	end
	return count
end
return Generator
