local Geometry = require(script.Parent.Utils.Geometry)
local Seed = require(script.Parent.Utils.Seed)
local Placement = require(script.Parent.Utils.Placement)
local Generator = {}

function Generator.build(region, theme, settings)
	local biome = region.BiomeConfig
	if not biome or biome.LandmarkProbability <= 0 then return nil end
	local rng = Seed.random(region.Seed, "landmark")
	if rng:NextNumber() > biome.LandmarkProbability then return nil end
	local total = 0
	for _, item in ipairs(theme.Landmarks) do total += item.Weight end
	local roll, chosen = rng:NextNumber(0, total), theme.Landmarks[1]
	for _, item in ipairs(theme.Landmarks) do
		roll -= item.Weight
		if roll <= 0 then chosen = item break end
	end
	local scale = math.clamp(rng:NextNumber(chosen.Scale[1], chosen.Scale[2]) * region.Radius / 65, 0.8, 4)
	local pos = region.LandmarkSlots[1]
	if not Placement.isClear(region, pos, 12, true) then return nil end
	local folder = Instance.new("Model")
	folder.Name, folder.Parent = "Landmark_" .. chosen.Id, region.VisualGeometry
	local p, a = theme.Palette[chosen.Category] or biome.RockColor, theme.Palette.Accent
	if chosen.Shape == "Spire" or chosen.Shape == "Mesa" then
		Geometry.part(folder, chosen.Id, Vector3.new(15*scale, 34*scale, 15*scale), pos + Vector3.new(0, 17*scale, 0), p, Enum.Material.Rock, true)
	elseif chosen.Shape == "Temple" or chosen.Shape == "Arena" then
		Geometry.part(folder, "Foundation", Vector3.new(40*scale, 3, 34*scale), pos + Vector3.new(0, 1.5, 0), p, Enum.Material.Slate, true)
		for x = -1, 1, 2 do for z = -1, 1, 2 do
			Geometry.part(folder, "Pillar", Vector3.new(3*scale, 18*scale, 3*scale), pos + Vector3.new(x*15*scale, 10*scale, z*12*scale), p, Enum.Material.Marble, true)
		end end
		Geometry.part(folder, "Lintel", Vector3.new(34*scale, 3*scale, 3*scale), pos + Vector3.new(0, 20*scale, -12*scale), a, Enum.Material.Marble, true)
	elseif chosen.Shape == "Pod" then
		Geometry.part(folder, "Pod", Vector3.new(18*scale, 12*scale, 24*scale), pos + Vector3.new(0, 6*scale, 0), theme.Palette.Technology, Enum.Material.Metal, true)
		Geometry.part(folder, "Door", Vector3.new(6*scale, 8*scale, 1), pos + Vector3.new(0, 4*scale, -12*scale), a, Enum.Material.Neon, false)
	elseif chosen.Shape == "Crater" then
		for i = 1, 12 do local angle = i*math.pi/6
			Geometry.part(folder, "Rim", Vector3.new(12*scale, 5*scale, 8*scale), pos + Vector3.new(math.cos(angle)*22*scale, 2*scale, math.sin(angle)*18*scale), p, Enum.Material.Rock, true)
		end
	elseif chosen.Shape == "Waterfall" then
		Geometry.part(folder, "Waterfall", Vector3.new(10*scale, 30*scale, 2), pos + Vector3.new(0, 15*scale, 0), biome.WaterColor, Enum.Material.Glass, false)
	elseif chosen.Shape == "Arch" then
		for x = -1, 1, 2 do Geometry.part(folder, "ArchPost", Vector3.new(4*scale, 18*scale, 4*scale), pos + Vector3.new(x*10*scale, 9*scale, 0), p, Enum.Material.Rock, true) end
		Geometry.part(folder, "ArchTop", Vector3.new(24*scale, 4*scale, 5*scale), pos + Vector3.new(0, 19*scale, 0), p, Enum.Material.Rock, true)
	end
	return folder
end
return Generator
