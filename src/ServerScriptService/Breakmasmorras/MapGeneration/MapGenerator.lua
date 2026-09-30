local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Breakmasmorras")
local Config = require(Shared.Config)
local ThemeRegistry = require(Shared.MapGeneration.ThemeRegistry)
local Settings = require(script.Parent.Settings)
local Seed = require(script.Parent.Utils.Seed)
local GraphGenerator = require(script.Parent.GraphGenerator)
local RegionGenerator = require(script.Parent.RegionGenerator)
local LayoutGenerator = require(script.Parent.LayoutGenerator)
local HeightGenerator = require(script.Parent.HeightGenerator)
local TerrainGenerator = require(script.Parent.TerrainGenerator)
local CliffGenerator = require(script.Parent.CliffGenerator)
local PathGenerator = require(script.Parent.PathGenerator)
local ConnectorGenerator = require(script.Parent.ConnectorGenerator)
local WaterGenerator = require(script.Parent.WaterGenerator)
local LandmarkGenerator = require(script.Parent.LandmarkGenerator)
local PropClusters = require(script.Parent.PropClusters)
local PropScatter = require(script.Parent.PropScatter)
local VegetationScatter = require(script.Parent.VegetationScatter)
local SecretGenerator = require(script.Parent.SecretGenerator)
local DebugRenderer = require(script.Parent.DebugRenderer)
local MapGenerator = {}

local function enforcePartBudget(root, regions, budget)
	local parts, removable = 0, {}
	for _, item in ipairs(root:GetDescendants()) do
		if item:IsA("BasePart") then
			parts += 1
			if item.Name == "TreeCanopy" or item.Name == "TreeTrunk" or item.Name == "ScatteredRock" then
				table.insert(removable, { Part = item, Priority = 1 })
			else
				local ancestor = item.Parent
				while ancestor and ancestor ~= root do
					if ancestor.Name == "Decoration" or ancestor.Name == "Detail" or ancestor.Name == "Vegetation" then
						table.insert(removable, { Part = item, Priority = 2 })
						break
					end
					ancestor = ancestor.Parent
				end
			end
		end
	end
	table.sort(removable, function(a, b) return a.Priority < b.Priority end)
	for _, candidate in ipairs(removable) do
		if parts <= budget then break end
		if candidate.Part.Parent then candidate.Part:Destroy(); parts -= 1 end
	end
	if parts > budget then warn(string.format("MapGenerator: orçamento de peças excedido (%d/%d); geometria de gameplay preservada.", parts, budget)) end
	return parts
end

function MapGenerator.generateMap(parent, options)
	options = options or {}
	local seed = options.Seed or Random.new():NextInteger(1, 2^30)
	local phases = options.Phases or require(Shared.DungeonPhases)
	local theme = ThemeRegistry.get(options.ThemeId or Config.MapTheme)
	local graph = GraphGenerator.generate({ Seed = seed, Phases = phases, RoomCount = options.RoomCount or Settings.RoomCount })
	local root = Instance.new("Folder")
	root.Name, root.Parent = "GeneratedDungeon_" .. tostring(seed), parent
	local regionsFolder, connectorsFolder = Instance.new("Folder"), Instance.new("Folder")
	regionsFolder.Name, regionsFolder.Parent = "Regions", root
	connectorsFolder.Name, connectorsFolder.Parent = "Connectors", root
	local regions, rooms, secrets = {}, {}, {}
	for _, node in pairs(graph.Nodes) do
		local phase = phases[node.PhaseIndex]
		local neighbors = {}
		for _, neighborId in ipairs(node.Connections) do table.insert(neighbors, graph.Nodes[neighborId]) end
		local region = RegionGenerator.generate(regionsFolder, node, phase, neighbors, theme, Settings)
		regions[node.Id] = region
	end
	for _, region in pairs(regions) do
		local rng = Seed.random(region.Seed, "region-geometry")
		HeightGenerator.profile(region, region.BiomeConfig, rng)
		TerrainGenerator.build(region.GameplayGeometry, region, region.BiomeConfig, Settings, rng)
		CliffGenerator.build(region.Terrain, region, region.BiomeConfig, Settings, rng)
		LayoutGenerator.build(region, theme)
		for _, opening in ipairs(region.Exits) do
			local path = PathGenerator.points(region.Center + Vector3.new(0, 0.45, 0), opening.Position,
				Settings.PathWidth, 5, Seed.random(region.Seed, "internal-path", opening.To), 4)
			PathGenerator.build(region.Path, path, region.BiomeConfig, "RegionPath", Enum.Material.Sand, false)
		end
		for _, opening in ipairs(region.Entrances) do
			local path = PathGenerator.points(region.Center + Vector3.new(0, 0.45, 0), opening.Position,
				Settings.PathWidth, 5, Seed.random(region.Seed, "internal-path", opening.To), 4)
			PathGenerator.build(region.Path, path, region.BiomeConfig, "RegionPath", Enum.Material.Sand, false)
		end
		WaterGenerator.buildRegion(region, theme, Settings)
		LandmarkGenerator.build(region, theme, Settings)
		PropClusters.build(region, theme, Settings)
		PropScatter.build(region, theme, Settings)
		VegetationScatter.build(region, theme, Settings)
		local secret = SecretGenerator.build(region, theme)
		if secret then table.insert(secrets, secret) end
		if region.MainIndex and not region.Optional then
			local phase = phases[region.PhaseIndex]
			rooms[region.MainIndex] = { Folder = region.Folder, Center = region.Center, Spawn = region.Spawn,
				Enemies = region.Enemies, Variant = region.Variant, LayoutName = region.LayoutName,
				PhaseIndex = region.PhaseIndex, RoomInPhase = region.RoomInPhase, Region = region,
				Phase = phase, NodeId = region.Id }
		end
	end
	WaterGenerator.markCrossings(graph, regions, seed)
	local connectors = {}
	for _, edge in ipairs(graph.Edges) do
		if edge.WaterCrossing then WaterGenerator.buildCrossing(connectorsFolder, regions[edge.From], regions[edge.To], Settings, theme) end
		local connector = ConnectorGenerator.build(connectorsFolder, edge, regions, theme, Settings, seed)
		if connector then table.insert(connectors, connector) end
	end
	DebugRenderer.build(root, graph, regions, connectors, Settings)
	local partCount = enforcePartBudget(root, regions, Settings.MaxMapParts)
	return { Root = root, Graph = graph, Regions = regions, Rooms = rooms, Connectors = connectors,
		Secrets = secrets, Theme = theme, Seed = seed, PartCount = partCount }
end

return MapGenerator
