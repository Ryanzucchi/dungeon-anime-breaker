local World = {}
local LOBBY_CENTER = Vector3.new(240, 0, 0)

local function part(parent, name, size, position, color, material)
    local value = Instance.new("Part")
    value.Name, value.Size, value.Position = name, size, position
    value.Anchored = true
    value.Color = color
    value.Material = material or Enum.Material.SmoothPlastic
    value.Parent = parent
    return value
end

local function label(parent, text, color)
    local billboard = Instance.new("BillboardGui")
    billboard.Name, billboard.Size = "LobbyLabel", UDim2.fromOffset(320, 64)
    billboard.StudsOffset = Vector3.new(0, 4, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = parent
    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Size = UDim2.fromScale(1, 1)
    title.Font = Enum.Font.GothamBold
    title.Text, title.TextColor3, title.TextScaled = text, color, true
    title.TextStrokeTransparency = 0.35
    title.Parent = billboard
end

local function createLobby()
    local existing = workspace:FindFirstChild("BreakmasmorrasLobby")
    if existing then existing:Destroy() end
    local folder = Instance.new("Folder")
    folder.Name, folder.Parent = "BreakmasmorrasLobby", workspace
    part(folder, "LobbyFloor", Vector3.new(112, 2, 112), LOBBY_CENTER + Vector3.new(0, -1, 0), Color3.fromRGB(39, 47, 62), Enum.Material.Slate)
    part(folder, "LobbyInset", Vector3.new(72, 0.25, 72), LOBBY_CENTER + Vector3.new(0, 0.12, 0), Color3.fromRGB(55, 67, 87), Enum.Material.SmoothPlastic)
    for _, side in ipairs({ -1, 1 }) do
        part(folder, "LobbyPillar", Vector3.new(3, 16, 3), LOBBY_CENTER + Vector3.new(side * 15, 8, -38), Color3.fromRGB(71, 81, 100), Enum.Material.Marble)
    end
    part(folder, "PortalLintel", Vector3.new(33, 3, 4), LOBBY_CENTER + Vector3.new(0, 16, -38), Color3.fromRGB(91, 104, 127), Enum.Material.Marble)
    local portal = part(folder, "DungeonPortal", Vector3.new(20, 12, 1), LOBBY_CENTER + Vector3.new(0, 7, -38), Color3.fromRGB(58, 211, 225), Enum.Material.Neon)
    portal.Transparency, portal.CanCollide, portal.CanTouch, portal.CanQuery = 0.28, false, false, false
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "EnterDungeonPrompt"
    prompt.ActionText, prompt.ObjectText = "Entrar na dungeon", "Portal de Masmorra"
    prompt.KeyboardKeyCode, prompt.GamepadKeyCode = Enum.KeyCode.Z, Enum.KeyCode.ButtonY
    prompt.HoldDuration, prompt.MaxActivationDistance, prompt.RequiresLineOfSight = 0.25, 14, false
    prompt.Parent = portal
    label(portal, "PORTAL DA MASMORRA", Color3.fromRGB(222, 252, 255))

    for index, item in ipairs({
        { "Coleção", -32, 23, Color3.fromRGB(114, 154, 230) },
        { "Summon", 32, 23, Color3.fromRGB(225, 186, 90) },
        { "Build", -32, -23, Color3.fromRGB(140, 205, 150) },
        { "Treino", 32, -23, Color3.fromRGB(198, 139, 220) },
    }) do
        local x, z = item[2], item[3]
        local stand = part(folder, "LobbyStand" .. index, Vector3.new(15, 1, 12), LOBBY_CENTER + Vector3.new(x, 0.65, z), item[4], Enum.Material.SmoothPlastic)
        local post = part(folder, "LobbyStandMarker" .. index, Vector3.new(2, 5, 2), LOBBY_CENTER + Vector3.new(x, 3.5, z), item[4], Enum.Material.Neon)
        post.CanCollide, post.CanTouch, post.CanQuery = false, false, false
        label(stand, item[1], Color3.fromRGB(245, 247, 252))
    end
    local spawn = Instance.new("SpawnLocation")
    spawn.Name, spawn.Size = "LobbySpawn", Vector3.new(12, 1, 12)
    spawn.Position = LOBBY_CENTER + Vector3.new(0, 0.5, 31)
    spawn.Anchored, spawn.Neutral, spawn.Duration = true, true, 0
    spawn.Transparency, spawn.CanCollide = 1, false
    spawn.Parent = folder
    return folder, spawn, prompt
end

function World.create(size)
    local existing = workspace:FindFirstChild("BreakmasmorrasArena")
    if existing then existing:Destroy() end
    local folder = Instance.new("Folder")
    folder.Name, folder.Parent = "BreakmasmorrasArena", workspace
    part(folder, "Floor", Vector3.new(size, 2, size), Vector3.new(0, -1, 0), Color3.fromRGB(63, 68, 78), Enum.Material.Slate)
    -- The dungeon is a continuous generated route; old arena perimeter walls would cut across it.
    local spawn = Instance.new("SpawnLocation")
    spawn.Name, spawn.Size, spawn.Position = "DungeonSpawn", Vector3.new(12, 1, 12), Vector3.new(0, 0.5, 52)
    spawn.Anchored, spawn.Neutral, spawn.Duration = true, true, 0
    spawn.Transparency, spawn.CanCollide = 1, false
    spawn.Parent = folder
    local actors = Instance.new("Folder")
    actors.Name, actors.Parent = "Enemies", folder
    local allies = Instance.new("Folder")
    allies.Name, allies.Parent = "Supports", folder
    local lobby, lobbySpawn, prompt = createLobby()
    local oldDungeon = workspace:FindFirstChild("BreakmasmorrasDungeon")
    if oldDungeon then oldDungeon:Destroy() end
    local dungeon = Instance.new("Folder")
    dungeon.Name, dungeon.Parent = "BreakmasmorrasDungeon", workspace
    return { Folder = folder, Enemies = actors, Supports = allies, Spawn = spawn,
        Lobby = lobby, LobbySpawn = lobbySpawn, PortalPrompt = prompt, Dungeon = dungeon }
end

return World
