local Geometry = require(script.Parent.Utils.Geometry)
local Renderer = {}
function Renderer.build(parent, graph, regions, connectors, settings)
	local enabled = settings.Debug
	if not (enabled.ShowRegions or enabled.ShowGraph or enabled.ShowSpawnZones or enabled.ShowReservedAreas or enabled.ShowConnectors or enabled.ShowPaths) then return end
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "Debug", parent
	for _, region in pairs(regions) do
		if enabled.ShowRegions then Geometry.debugBox(folder, "Region", region.Center, Vector3.new(region.Size, 1, region.Size), Color3.fromRGB(70,160,255)) end
		if enabled.ShowSpawnZones then for _, p in ipairs(region.SpawnZones) do Geometry.debugBox(folder, "SpawnZone", p, Vector3.new(16,1,16), Color3.fromRGB(90,255,130)) end end
		if enabled.ShowReservedAreas then for _, r in ipairs(region.ReservedAreas) do
			if r.Start and r.Finish then Geometry.segment(folder, r.Kind, r.Start, r.Finish, r.Radius*2, 0.5, Color3.fromRGB(255,180,50), Enum.Material.Neon, false)
			elseif r.Center then Geometry.debugBox(folder, r.Kind, r.Center, Vector3.new(r.Radius*2,1,r.Radius*2), Color3.fromRGB(255,180,50)) end
		end end
	end
	if enabled.ShowPaths then
		for _, region in pairs(regions) do
			for _, part in ipairs(region.Path:GetChildren()) do
				if part:IsA("BasePart") and part.Name == "RegionPath" then part.Transparency = 0.2; part.Material = Enum.Material.Neon end
			end
		end
	end
	if enabled.ShowGraph then for _, edge in ipairs(graph.Edges) do local a,b=regions[edge.From],regions[edge.To]; if a and b then Geometry.segment(folder,"GraphEdge",a.Center,b.Center,0.35,0.35,Color3.fromRGB(255,60,80),Enum.Material.Neon,false) end end end
	if enabled.ShowConnectors then for _, c in ipairs(connectors) do for _, p in ipairs(c.Parts or {}) do if p:IsA("BasePart") then p.Transparency=0.35; p.Material=Enum.Material.Neon end end end end
end
return Renderer
