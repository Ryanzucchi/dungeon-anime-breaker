local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")
local HttpService = game:GetService("HttpService")
local Shared = ReplicatedStorage:WaitForChild("Breakmasmorras")
local Config, Characters, Rules = require(Shared.Config), require(Shared.Characters), require(Shared.Rules)
local Progression = require(Shared.Progression)
local DungeonPhases = require(Shared.DungeonPhases)
local Profiles = require(script.Profiles)
local profiles, random = Profiles.new(), Random.new()
local World, Rigs = require(script.World), require(script.Rigs)
local Combat, Enemies, Supports = require(script.Combat), require(script.Enemies), require(script.Supports)

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = Shared
local function remote(name)
    local event = Instance.new("RemoteEvent")
    event.Name, event.Parent = name, remotes
    return event
end
local action, snapshot, effects, notice = remote("Action"), remote("Snapshot"), remote("Effects"), remote("Notice")
local economy = remote("Economy")

local world = World.create(Config.ArenaSize)
if not PhysicsService:IsCollisionGroupRegistered("BreakmasmorrasActors") then
    PhysicsService:RegisterCollisionGroup("BreakmasmorrasActors")
end
PhysicsService:CollisionGroupSetCollidable("BreakmasmorrasActors", "BreakmasmorrasActors", false)
local success, errorMessage = pcall(Rigs.initialize)
if not success then
    warn("Breakmasmorras: falha ao gerar R15 básico: " .. tostring(errorMessage))
    return
end
Players.CharacterAutoLoads = false
local states = {}
local combat = Combat.new(states, world, effects)
local supports = Supports.new(combat)
local function notifyAll(message) notice:FireAllClients(message) end

local function applyHealth(player, preserve)
    local state = states[player]
    local _, _, humanoid = Combat.actor(player)
    if not state or not humanoid then return end
    local ratio = preserve and humanoid.Health / humanoid.MaxHealth or 1
    local unit = state.Units[state.Main]
    humanoid.MaxHealth = Rules.damage(Characters[Rules.baseId(state.Main)].HP, unit.Level, unit.Shiny) * Progression.bonuses(state).HP
    humanoid.Health = math.max(1, humanoid.MaxHealth * ratio)
    humanoid.DisplayName = Characters[Rules.baseId(state.Main)].Name
end

local enemies = Enemies.new(combat, function(enemy, amount)
    for player in pairs(enemy.Contributors) do
        local state = states[player]
        if state then
            Rules.addXP(state.Units[state.Main], amount, Config.MaxLevel, Config.xpForLevel)
            if state.Support and state.SupportParticipated then
                Rules.addXP(state.Units[state.Support], math.floor(amount * Config.SupportXPRatio), Config.MaxLevel, Config.xpForLevel)
            end
            applyHealth(player, true)
            state.Gold = state.Gold + (enemy.FinalBoss and 100 or (enemy.Elite and 32 or (enemy.Boss and 55 or 8)))
            if enemy.FinalBoss then
                state.Spins, state.Runs = state.Spins + 3, state.Runs + 1
                if #state.Inventory < Config.InventoryLimit then
                    local itemSlots = { "Weapon", "Armor", "Accessory", "Artifact" }
                    local slot = itemSlots[random:NextInteger(1, #itemSlots)]
                    local rare = random:NextNumber() < 0.25
                    local item = { Id = HttpService:GenerateGUID(false), Slot = slot,
                        Name = slot .. " do Guardião", Rarity = rare and "Rare" or "Common",
                        Power = random:NextInteger(rare and 12 or 4, rare and 20 or 10) }
                    table.insert(state.Inventory, item)
                    notice:FireClient(player, "Boss derrotado: +100 ouro, +3 rolls, " .. item.Name .. " (" .. item.Rarity .. ")")
                else
                    state.Gold = state.Gold + 30
                    notice:FireClient(player, "Inventário cheio: loot convertido em +30 ouro. +3 rolls recebidos.")
                end
            end
            state.EconomyDirty = true
        end
    end
end, notifyAll, function(player) supports:remove(player) end)

local function spawnPlayer(player)
    if not states[player] or not player.Parent then return end
    local description = Rigs.description()
    local ok, message = pcall(function() player:LoadCharacterWithHumanoidDescriptionAsync(description) end)
    description:Destroy()
    if not ok then warn("Breakmasmorras: respawn falhou: " .. tostring(message)) end
end

local function enterDungeon(player)
    if not states[player] or states[player].InDungeon or not Combat.actor(player) then return false end
    local entered = enemies:start(player)
    if entered then
        supports:equip(player)
        local playerState = states[player]
        playerState.SupportParticipated = false
        return true
    end
    return false
end
world.PortalPrompt.Triggered:Connect(enterDungeon)

local function addPlayer(player)
    if states[player] then return end
    local profile, status = profiles:load(player)
    if not profile then player:Kick(status) return end
    if not player.Parent then profiles:save(player, profile, true) return end
    states[player] = profile
    local runtime = { Energy = 100,
        Shield = 0, ShieldUntil = 0, InvulnerableUntil = 0, Cooldowns = {},
        Haste = 1, HasteUntil = 0, Combo = 0, SealReady = false, LastCombat = -100,
        NextSand = 0, SupportParticipated = false, InDungeon = false, EconomyDirty = true, SaveStatus = status,
        Bucket = { tokens = Config.RemoteBurst, time = os.clock() } }
    for key, value in pairs(runtime) do profile[key] = value end
    print("Breakmasmorras: perfil carregado: " .. player.Name .. " · " .. status)
    player.CharacterAdded:Connect(function(model)
        local humanoid = model:WaitForChild("Humanoid", 10)
        local root = model:WaitForChild("HumanoidRootPart", 10)
        local state = states[player]
        if not humanoid or not root or not state then return end
        local spawn = state.InDungeon and world.Spawn or world.LobbySpawn
        model:PivotTo(CFrame.new(spawn.Position + Vector3.new(0, 5, 0)))
        for _, child in ipairs(model:GetDescendants()) do
            if child:IsA("BasePart") then child.CollisionGroup = "BreakmasmorrasActors" end
        end
        state.Shield, state.Energy, state.Combo = 0, 100, 0
        state.InvulnerableUntil = os.clock() + 2
        applyHealth(player, false)
        if state.InDungeon then supports:equip(player) else supports:remove(player) end
        humanoid.Died:Connect(function()
            supports:remove(player)
            task.delay(3, function() spawnPlayer(player) end)
        end)
    end)
    task.spawn(function() spawnPlayer(player) end)
end

action.OnServerEvent:Connect(function(player, verb, value, aim)
    local state = states[player]
    if not state or not Rules.consumeBucket(state.Bucket, os.clock(), Config.RemoteRate, Config.RemoteBurst) then return end
    if type(verb) ~= "string" then return end
    if verb == "Cast" then
        combat:cast(player, value, aim)
    elseif verb == "Select" or verb == "Support" then
        if enemies.Active then notice:FireClient(player, "Troque Main/Support entre as runs.") return end
        if type(value) ~= "string" or #value > 32 or not Characters[Rules.baseId(value)] then return end
        if not state.Units[value] then notice:FireClient(player, "Você ainda não possui este personagem. Use o roll para obtê-lo.") return end
        if verb == "Select" then
            if value == state.Support then supports:remove(player) state.Support = nil end
            state.Main, state.Combo, state.SealReady = value, 0, false
            state.HasteUntil, state.NextSand = 0, os.clock() + 10
            applyHealth(player, true)
        else
            if value == state.Main then notice:FireClient(player, "Escolha outro personagem como Support.") return end
            state.Support = value
            supports:equip(player)
        end
        state.EconomyDirty = true
    elseif verb == "EquipItem" then
        if enemies.Active or type(value) ~= "string" or #value > 64 then return end
        if Progression.equip(state, value) then
            applyHealth(player, true)
            state.EconomyDirty = true
            notice:FireClient(player, "Equipamento aplicado à build.")
        end
    elseif verb == "Roll" then
        if enemies.Active then notice:FireClient(player, "Faça rolls entre as runs.") return end
        local now = os.clock()
        if now < (state.Cooldowns.Roll or 0) then return end
        state.Cooldowns.Roll = now + 1
        local result = Progression.roll(state, Config,
            function(low, high) return random:NextInteger(low, high) end,
            function() return random:NextNumber() end)
        if not result then notice:FireClient(player, "Sem rolls. Derrote o boss para ganhar mais.") return end
        state.EconomyDirty = true
        notice:FireClient(player, Characters[result.Id].Name .. (result.Shiny and " SHINY (+20%)" or "")
            .. (result.Duplicate and " · duplicata: +1 Character Soul" or " · novo personagem nível 1"))
    elseif verb == "Start" then
        enterDungeon(player)
    elseif verb == "Potion" then
        local _, _, humanoid = Combat.actor(player)
        local now = os.clock()
        if humanoid and now >= (state.Cooldowns.Potion or 0) then
            state.Cooldowns.Potion = now + 20
            humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + 65)
        end
    elseif verb == "SupportCommand" then
        local ally = supports.Actors[player]
        -- Reagrupar nunca reduz a recarga da habilidade do Support.
        if ally then ally.NextMove = 0 end
    end
end)

Players.PlayerAdded:Connect(addPlayer)
Players.PlayerRemoving:Connect(function(player)
    supports:remove(player)
    enemies:removePlayer(player)
    local state = states[player]
    states[player] = nil
    if state then profiles:save(player, Progression.pack(state), true) end
end)
for _, player in ipairs(Players:GetPlayers()) do addPlayer(player) end
local accumulator, aiAccumulator = 0, 0
RunService.Heartbeat:Connect(function(delta)
    combat:update(math.min(delta, 0.25))
    aiAccumulator = aiAccumulator + delta
    if aiAccumulator >= 0.1 then
        aiAccumulator = 0
        enemies:update()
        supports:update()
    end
    accumulator = accumulator + delta
    if accumulator >= 0.15 then
        accumulator = 0
        for player, state in pairs(states) do
            local _, _, humanoid = Combat.actor(player)
            local cooldowns = {}
            for slot, finish in pairs(state.Cooldowns) do cooldowns[slot] = math.max(0, finish - os.clock()) end
            local boss
            for _, enemy in ipairs(combat.Enemies) do
                if enemy.Boss and enemy.Humanoid.Health > 0 then
                    boss = { Name = enemy.Name, HP = enemy.Humanoid.Health, MaxHP = enemy.Humanoid.MaxHealth,
                        Posture = enemy.Posture, MaxPosture = enemy.MaxPosture }
                    break
                end
            end
            snapshot:FireClient(player, { Main = state.Main, Support = state.Support, InDungeon = state.InDungeon,
                PhaseName = enemies.CurrentPhase and enemies.CurrentPhase.Name or nil, PhaseCount = #DungeonPhases * 5,
                Units = state.Units, Energy = state.Energy, Shield = state.Shield,
                HP = humanoid and humanoid.Health or 0, MaxHP = humanoid and humanoid.MaxHealth or 1,
                Cooldowns = cooldowns, Active = enemies.Active, Stage = enemies.Stage,
                EnemyCount = #combat.Enemies, Boss = boss, SaveStatus = state.SaveStatus })
            if state.EconomyDirty then
                state.EconomyDirty = false
                economy:FireClient(player, { Gold = state.Gold, Spins = state.Spins,
                    Inventory = state.Inventory, Equipment = state.Equipment, Pity = state.Pity })
            end
        end
    end
end)

task.spawn(function()
    while task.wait(Config.SaveInterval) do
        for player, state in pairs(states) do
            task.spawn(function()
                profiles:save(player, Progression.pack(state), false)
                local session = profiles.Sessions[player]
                if session then state.SaveStatus = session.Status end
            end)
        end
    end
end)
game:BindToClose(function()
    local pending = 0
    for player, state in pairs(states) do
        pending = pending + 1
        task.spawn(function()
            profiles:save(player, Progression.pack(state), true)
            pending = pending - 1
        end)
    end
    local deadline = os.clock() + 25
    while pending > 0 and os.clock() < deadline do task.wait(0.1) end
end)

