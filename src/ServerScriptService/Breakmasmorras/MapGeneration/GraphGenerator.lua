local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Breakmasmorras")
local Settings = require(script.Parent.Settings)
local Seed = require(script.Parent.Utils.Seed)
local GraphGenerator = {}
GraphGenerator.NodeTypes = { "Start", "Traversal", "Combat", "Arena", "Elite", "Treasure", "Puzzle", "Secret", "Vista", "Rest", "Transition", "Boss" }
local sizeWeights = {
    { Id = "Small", Weight = 22 }, { Id = "Medium", Weight = 40 },
    { Id = "Large", Weight = 23 }, { Id = "Arena", Weight = 12 }, { Id = "Landmark", Weight = 3 },
}
local function addEdge(graph, fromId, toId, optional)
    table.insert(graph.Edges, { From = fromId, To = toId, Optional = optional == true })
    table.insert(graph.Nodes[fromId].Connections, toId)
    table.insert(graph.Nodes[toId].Connections, fromId)
end
function GraphGenerator.generate(options)
    local seed = options.Seed
    local phases = options.Phases
    local count = options.RoomCount or Settings.RoomCount
    assert(type(seed) == "number" and type(phases) == "table" and #phases > 0, "MapGraph requer Seed e fases")
    local rng = Seed.random(seed, "graph")
    local graph = { Seed = seed, Nodes = {}, Edges = {}, MainRoute = {}, Branches = {} }
    local x = 0
    for index = 1, count do
        if index > 1 then
            x = x + rng:NextInteger(-22, 22)
        end
        local progress = (index - 1) / math.max(1, count - 1)
        local elevation = index == count and 76 or (index == 1 and 0 or math.floor(progress * 70 + rng:NextInteger(-3, 3) + 0.5))
        local phaseIndex = math.min(#phases, math.ceil(index / math.max(1, math.ceil(count / #phases))))
        local phase = phases[phaseIndex]
        local sizeRoll, total = rng:NextNumber(0, 100), 0
        local sizeId = "Medium"
        for _, choice in ipairs(sizeWeights) do
            total = total + choice.Weight
            if sizeRoll <= total then sizeId = choice.Id break end
        end
        local nodeType = "Traversal"
        if index == 1 then nodeType = "Start"
        elseif index == count then nodeType = "Boss"
        elseif index % 5 == 0 then nodeType = "Arena"
        elseif index > 1 and (index - 1) % 5 == 0 then nodeType = "Transition"
        elseif index % 7 == 0 then nodeType = "Elite"
        elseif index % 9 == 0 then nodeType = "Rest"
        elseif index % 8 == 0 then nodeType = "Vista"
        elseif index % 4 == 0 then nodeType = "Combat"
        end
        local id = string.format("main_%02d", index)
        graph.Nodes[id] = {
            Id = id, Type = nodeType, Seed = Seed.derive(seed, "region", index), Biome = phase.Biome,
            Difficulty = index, Connections = {}, Elevation = elevation,
            Size = (nodeType == "Boss" or nodeType == "Arena") and "Arena" or sizeId,
            Importance = nodeType == "Boss" and 10 or 1,
            Optional = false, MainIndex = index, Position = Vector3.new(x, elevation, -(index - 1) * Settings.MainRouteSpacing),
            PhaseId = phase.Id, PhaseIndex = phaseIndex,
        }
        table.insert(graph.MainRoute, id)
        if index > 1 then addEdge(graph, graph.MainRoute[index - 1], id, false) end
    end
    for index = 5, count - 5, 5 do
        local rngBranch = Seed.random(seed, "branch", index)
        local mainId, nextId = graph.MainRoute[index], graph.MainRoute[index + 1]
        local sign = rngBranch:NextNumber() < 0.5 and -1 or 1
        local id = string.format("secret_%02d", index)
        local middle = (graph.Nodes[mainId].Position + graph.Nodes[nextId].Position) * 0.5
        local sizeRoll = rngBranch:NextNumber()
        local nodeType = sizeRoll < 0.5 and "Secret" or (sizeRoll < 0.82 and "Treasure" or "Puzzle")
        graph.Nodes[id] = {
            Id = id, Type = nodeType, Seed = Seed.derive(seed, "secret", index), Biome = graph.Nodes[mainId].Biome,
            Difficulty = index, Connections = {}, Elevation = graph.Nodes[mainId].Elevation + rngBranch:NextInteger(-3, 3),
            Size = "Small", Importance = 0.5, Optional = true, MainIndex = index,
            Position = middle + Vector3.new(sign * Settings.SideBranchOffset, 0, 0), PhaseId = graph.Nodes[mainId].PhaseId,
            PhaseIndex = graph.Nodes[mainId].PhaseIndex,
        }
        addEdge(graph, mainId, id, true)
        addEdge(graph, id, nextId, true)
        table.insert(graph.Branches, id)
    end
    return graph
end
return GraphGenerator
