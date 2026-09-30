local Geometry = require(script.Parent.Utils.Geometry)
local Generator = {}
function Generator.build(region, theme)
	if region.Type ~= "Secret" and region.Type ~= "Treasure" and region.Type ~= "Puzzle" then return nil end
	local position = region.Center + Vector3.new(0, 1, 0)
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "SecretReward", region.Folder
	local chest = Geometry.part(folder, "TreasureChest", Vector3.new(7, 4, 5), position, theme.Palette.Accent, Enum.Material.Metal, true)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = region.Type == "Puzzle" and "Ativar" or "Abrir"
	prompt.ObjectText = region.Type == "Puzzle" and "Santuário" or (region.Type == "Secret" and "Baú secreto" or "Tesouro")
	prompt.HoldDuration, prompt.MaxActivationDistance, prompt.RequiresLineOfSight = 0.4, 10, false
	prompt.Parent = chest
	return { Node = region.Id, Region = region, Chest = chest, Prompt = prompt, Claimed = false }
end
return Generator
