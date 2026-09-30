local MapGenerator = require(script.Parent.MapGeneration.MapGenerator)
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Breakmasmorras")
local Generator = {}

function Generator.generateMap(parent, options)
	return MapGenerator.generateMap(parent, options)
end

-- Compatibility adapter for older callers that still request one region.
function Generator.generate(parent, phase, roomNumber, seed)
	local phases = require(Shared.DungeonPhases)
	local phaseIndex = math.ceil(roomNumber / 5)
	if phase and phases[phaseIndex] then
		phases = table.clone(phases)
		phases[phaseIndex] = phase
	end
	local runSeed = seed or Random.new():NextInteger(1, 2^30)
	local result = MapGenerator.generateMap(parent, { Seed = runSeed, Phases = phases, RoomCount = #phases * 5 })
	local room = result.Rooms[roomNumber]
	assert(room, "Sala inexistente: " .. tostring(roomNumber))
	room.Graph, room.Regions, room.Connectors, room.Secrets, room.Theme = result.Graph, result.Regions, result.Connectors, result.Secrets, result.Theme
	return room
end

return Generator
