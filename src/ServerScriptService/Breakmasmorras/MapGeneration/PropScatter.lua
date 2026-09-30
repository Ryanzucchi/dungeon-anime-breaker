local Geometry = require(script.Parent.Utils.Geometry)
local Seed = require(script.Parent.Utils.Seed)
local Placement = require(script.Parent.Utils.Placement)
local Generator = {}
function Generator.build(region, theme, settings)
	local rng = Seed.random(region.Seed, "props")
	local biome, made = region.BiomeConfig, 0
	local count = math.floor(settings.MaxVisualPropsPerRegion * biome.RockDensity * rng:NextNumber(0.35, 0.8))
	local variants = theme.Props.Rock or { "SmallRock", "Boulder" }
	for i = 1, count do
		local pos
		for _ = 1, 8 do
			local angle, radius = rng:NextNumber(0, math.pi*2), rng:NextNumber(region.Radius*0.66, region.Radius*0.9)
			local candidate = region.Center + Vector3.new(math.cos(angle)*radius, 0, math.sin(angle)*radius)
			if Placement.isClear(region, candidate, 7) then pos = candidate break end
		end
		if not pos then continue end
		local size = rng:NextNumber(3, 8)
		local name = variants[rng:NextInteger(1, #variants)]
		local heightScale = rng:NextNumber(0.5,1.7)
		Geometry.block(region.Detail, name, Vector3.new(size, size*heightScale, size), pos + Vector3.new(0,size*heightScale/2,0), biome.RockColor, Enum.Material.Rock, false)
		made += 1
	end
	return made
end
return Generator
