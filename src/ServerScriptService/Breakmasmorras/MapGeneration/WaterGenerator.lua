local Geometry = require(script.Parent.Utils.Geometry)
local Seed = require(script.Parent.Utils.Seed)
local Placement = require(script.Parent.Utils.Placement)
local Generator = {}
function Generator.buildRegion(region, theme, settings)
	local biome = region.BiomeConfig
	local rng = Seed.random(region.Seed, "water")
	if rng:NextNumber() > (biome.WaterProbability or 0) then return nil end
	local zone = region.DecorationZones[2].Center
	local isLake = biome.WaterForm == "Lake" and rng:NextNumber() < (biome.LakeProbability or 0.4)
	local size = isLake and math.min(rng:NextNumber(42, 68), region.Radius * 1.1)
		or math.min(rng:NextNumber(22, 42), region.Radius * 0.75)
	if not Placement.isClear(region, zone, size * 0.28, true) then return nil end
	local water = Geometry.part(region.VisualGeometry, isLake and "Lake" or "Pond", Vector3.new(size, 1, size*0.72), zone + Vector3.new(0, 0.35, 0), biome.WaterColor, Enum.Material.Glass, false)
	water.Transparency, water.CanTouch, water.CanQuery = 0.28, false, false
	return water
end
function Generator.buildCrossing(parent, from, to, settings, theme)
	local delta = to.Center - from.Center
	local direction = Vector3.new(delta.X, 0, delta.Z).Unit
	local center = (from.Center + to.Center) * 0.5
	local waterColor = theme.Biomes[from.Biome].WaterColor
	local water = Geometry.part(parent, "RiverCrossingWater", Vector3.new(settings.ConnectorWidth + 10, 0.8, 22),
		CFrame.lookAt(center - Vector3.new(0, 1.3, 0), center + direction), waterColor, Enum.Material.Glass, false)
	water.Transparency, water.CanTouch, water.CanQuery = 0.3, false, false
	return water
end
function Generator.markCrossings(graph, regions, seed)
	for _, edge in ipairs(graph.Edges) do
		local from, to = regions[edge.From], regions[edge.To]
		local rng = Seed.random(seed, "water-edge", edge.From .. edge.To)
		local chance = math.max(from.BiomeConfig.WaterProbability or 0, to.BiomeConfig.WaterProbability or 0)
		edge.WaterCrossing = not edge.Optional and rng:NextNumber() < chance * 0.42
	end
end
return Generator
