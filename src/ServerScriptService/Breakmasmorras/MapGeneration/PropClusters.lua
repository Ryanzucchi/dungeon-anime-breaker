local Geometry = require(script.Parent.Utils.Geometry)
local Seed = require(script.Parent.Utils.Seed)
local Placement = require(script.Parent.Utils.Placement)
local Generator = {}

function Generator.build(region, theme, settings)
	local rng = Seed.random(region.Seed, "clusters")
	if rng:NextNumber() > region.BiomeConfig.LandmarkProbability then return 0 end
	local options = {}
	for key in pairs(theme.Structures) do table.insert(options, key) end
	table.sort(options)
	if #options == 0 then return 0 end
	local key = options[rng:NextInteger(1, #options)]
	local center = region.DecorationZones[1].Center
	if not Placement.isClear(region, center, 12) then center = region.DecorationZones[2].Center end
	if not Placement.isClear(region, center, 12) then return 0 end
	local palette = theme.Palette
	local category = theme.StructureCategories and theme.StructureCategories[key]
	local color = palette[category] or palette.Ruins or region.BiomeConfig.RockColor
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "StoryCluster_" .. key, region.Detail
	local count = 0
	for i, item in ipairs(theme.Structures[key] or {}) do
		if count >= settings.MaxVisualPropsPerRegion then break end
		local angle = i * 2.4
		local pos = center + Vector3.new(math.cos(angle)*i*3, 0, math.sin(angle)*i*3)
		if Placement.isClear(region, pos, 4) then
			Geometry.part(folder, item, Vector3.new(4+rng:NextInteger(0,4), 3+rng:NextInteger(0,5), 4+rng:NextInteger(0,4)), pos + Vector3.new(0, 2, 0), color, Enum.Material.Rock, false)
			count += 1
		end
	end
	return count
end
return Generator
