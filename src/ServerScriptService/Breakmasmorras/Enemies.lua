local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Breakmasmorras")
local Config = require(Shared.Config)
local Phases = require(Shared.DungeonPhases)
local Generator = require(script.Parent.DungeonGenerator)
local Combat = require(script.Parent.Combat)
local Rigs = require(script.Parent.Rigs)
local EnemyCatalog = require(script.Parent.EnemyCatalog)
local Enemies = {}
Enemies.__index = Enemies
local ROOMS_PER_PHASE = 5
local TOTAL_ROOMS = #Phases * ROOMS_PER_PHASE

function Enemies.new(combat, onReward, notify, onExit)
    return setmetatable({ Combat = combat, Reward = onReward, Notify = notify, OnExit = onExit,
        Active = false, Stage = 0, Pending = false, Generation = 0, CurrentPhase = nil,
        CurrentRoom = nil, Participants = {}, RunSeed = 0, Rooms = {}, ActivatedRooms = {}, SecretRewards = {} }, Enemies)
end

function Enemies:nearest(position, maxDistance)
    local best, targetRoot, nearest = nil, nil, maxDistance or 160
    for _, player in ipairs(Players:GetPlayers()) do
        if self.Participants[player] and self.Combat.States[player] then
            local _, root = Combat.actor(player)
            if root and (root.Position - position).Magnitude < nearest then
                best, targetRoot, nearest = player, root, (root.Position - position).Magnitude
            end
        end
    end
    return best, targetRoot, nearest
end

function Enemies:spawn(position, kind)
    local spec = assert(EnemyCatalog[kind], "Tipo de inimigo não catalogado: " .. tostring(kind))
    local identity, config = spec.Identity, spec.Config
    local model, humanoid, root = Rigs.spawn(self.Combat.World.Enemies, identity.Name, position,
        config.MaxHealth, config.WalkSpeed, identity.Color)
    if config.ModelScale and config.ModelScale ~= 1 then model:ScaleTo(config.ModelScale) end
    local enemy = { Model = model, Humanoid = humanoid, Root = root, Boss = config.IsBoss,
        FinalBoss = config.IsFinalBoss, Elite = config.IsElite, Kind = kind, Name = identity.Name,
        Config = config, Behavior = spec.Behavior, Posture = 0, MaxPosture = config.MaxPosture,
        BreakUntil = 0, StunUntil = 0, SlowUntil = 0, NextAttack = os.clock() + 1.2,
        NextMove = 0, Contributors = {}, Casting = false }
    table.insert(self.Combat.Enemies, enemy)
    humanoid.Died:Connect(function()
        self.Reward(enemy, config.RewardXP)
        if config.IsFinalBoss then
            self.BossDefeated = true
            local generation = self.Generation
            task.delay(4, function()
                if self.Active and self.Generation == generation and self.BossDefeated then
                    self.Active = false
                    self.Notify("Chefe derrotado! A run terminou; retorno ao lobby.")
                    self:returnToLobby()
                end
            end)
        end
        Debris:AddItem(model, 1.5)
    end)
end

function Enemies:movePlayer(player, position)
    if player.Character and player.Character.Parent then
        player.Character:PivotTo(CFrame.new(position))
    end
end

function Enemies:teleportParticipants(position)
    for player in pairs(self.Participants) do self:movePlayer(player, position) end
end

function Enemies:returnToLobby()
    for player in pairs(self.Participants) do
        local state = self.Combat.States[player]
        if state then state.InDungeon = false end
        self:movePlayer(player, self.Combat.World.LobbySpawn.Position + Vector3.new(0, 5, 0))
        if self.OnExit then self.OnExit(player) end
        if player.Parent then self.Notify(player.Name .. " voltou ao lobby.") end
    end
    self.Participants, self.CurrentPhase, self.CurrentRoom, self.Rooms, self.ActivatedRooms, self.SecretRewards = {}, nil, nil, {}, {}, {}
    for _, enemy in ipairs(self.Combat.Enemies) do
        if enemy.Model and enemy.Model.Parent then enemy.Model:Destroy() end
    end
    table.clear(self.Combat.Enemies)
    self.Combat.World.Dungeon:ClearAllChildren()
end

function Enemies:start(player)
    if not player or not self.Combat.States[player] then return false end
    local state = self.Combat.States[player]
    if not self.Active then
        self.Generation = self.Generation + 1
        self.Active, self.Stage, self.Pending = true, 0, false
        self.Participants = {}
        self.RunSeed = Random.new():NextInteger(1, 2^30)
        self.Rooms, self.ActivatedRooms, self.BossDefeated = {}, {}, false
        self.Combat.World.Dungeon:ClearAllChildren()
        local generated = Generator.generateMap(self.Combat.World.Dungeon, {
            Seed = self.RunSeed, Phases = Phases, RoomCount = TOTAL_ROOMS, ThemeId = Config.MapTheme,
        })
        self.Rooms, self.SecretRewards = generated.Rooms, generated.Secrets
        for _, reward in ipairs(self.SecretRewards) do
            reward.Prompt.Triggered:Connect(function(player)
                if reward.Claimed or not self.Active or not self.Participants[player] then return end
                reward.Claimed = true
                reward.Prompt.Enabled = false
                local state = self.Combat.States[player]
                if state then
					local amount = reward.Region.Type == "Treasure" and 45 or (reward.Region.Type == "Puzzle" and 35 or 25)
                    state.Gold += amount
                    state.EconomyDirty = true
                    self.Notify(player.Name .. " encontrou um tesouro secreto: +" .. amount .. " ouro.")
                end
                reward.Chest.Color = Color3.fromRGB(110, 205, 120)
            end)
        end
    end
    if self.Participants[player] then return false end
    self.Participants[player] = true
    state.InDungeon = true
    if not self.ActivatedRooms[1] then self:activateRoom(1) end
    self:movePlayer(player, self.CurrentRoom.Spawn + Vector3.new(0, 1, 0))
    return true
end

function Enemies:removePlayer(player)
    self.Participants[player] = nil
    if next(self.Participants) == nil and self.Active then
        self.Generation = self.Generation + 1
        self.Active, self.Pending, self.Stage, self.CurrentPhase, self.CurrentRoom, self.Rooms, self.ActivatedRooms, self.SecretRewards = false, false, 0, nil, nil, {}, {}, {}
        for _, enemy in ipairs(self.Combat.Enemies) do
            if enemy.Model and enemy.Model.Parent then enemy.Model:Destroy() end
        end
        table.clear(self.Combat.Enemies)
        self.Combat.World.Dungeon:ClearAllChildren()
    end
end

function Enemies:activateRoom(roomNumber)
    if not self.Active or self.ActivatedRooms[roomNumber] then return end
    self.ActivatedRooms[roomNumber] = true
    local phaseIndex = math.ceil(roomNumber / ROOMS_PER_PHASE)
    local phase = Phases[phaseIndex]
    if roomNumber >= self.Stage then
        self.Stage, self.CurrentPhase, self.CurrentRoom = roomNumber, phase, self.Rooms[roomNumber]
        self.Combat.World.Spawn.Position = self.CurrentRoom.Spawn + Vector3.new(0, -3.5, 0)
    end
    local room = self.Rooms[roomNumber]
    if room.Region and room.Region.Type == "Rest" then
        for participant in pairs(self.Participants) do
            local _, _, humanoid = Combat.actor(participant)
            if humanoid then humanoid.Health = humanoid.MaxHealth end
        end
        self.Notify("Área de descanso: equipe recuperada.")
    end
    local seed = bit32.bxor(self.RunSeed, roomNumber * 7919, phaseIndex * 104729)
    local rng = Random.new(seed + 17)
    for index, position in ipairs(room.Enemies) do
        local kind = "melee"
        if roomNumber == TOTAL_ROOMS then
            kind = "boss"
        elseif roomNumber == 15 and index == 1 then
            kind = "mini_boss"
        elseif room.Region and room.Region.Type == "Elite" and index == 1 then
            kind = "elite"
        elseif roomNumber % ROOMS_PER_PHASE == 0 and index == 1 then
            kind = "elite"
        else
            kind = phase.EnemyPool[rng:NextInteger(1, #phase.EnemyPool)]
        end
        self:spawn(position, kind)
    end
    self.Notify(string.format("Nova área: sala %d/%d · %s · layout %02d: %s", roomNumber, TOTAL_ROOMS,
        phase.Name, room.Variant, room.LayoutName))
end

function Enemies:attack(enemy, player, targetRoot)
    local now = os.clock()
    local profile = enemy.Behavior.Attack
    local enraged = enemy.Boss and profile.EnrageAtHealth
        and enemy.Humanoid.Health < enemy.Humanoid.MaxHealth * profile.EnrageAtHealth
    enemy.NextAttack = now + (enraged and profile.EnragedCooldown or profile.Cooldown)
    enemy.Casting = true
    local origin = enemy.Root.Position
    enemy.AttackNumber = (enemy.AttackNumber or 0) + 1
    local stomp = profile.StompEvery and enemy.AttackNumber % profile.StompEvery == 0
    local center = stomp and origin or (profile.TargetMode == "target" and targetRoot.Position or origin)
    local radius = stomp and profile.StompRadius or profile.Radius
    local damage = stomp and (profile.StompDamage or profile.Damage) or profile.Damage
    local delay = profile.Windup
    self.Combat:emit("telegraph", center, Color3.fromRGB(255, 80, 85), radius, nil, delay)
    task.delay(delay, function()
        enemy.Casting = false
        if not enemy.Model.Parent or enemy.Humanoid.Health <= 0 then return end
        if os.clock() < enemy.StunUntil or os.clock() < enemy.BreakUntil then return end
        for candidate in pairs(self.Participants) do
            local _, root = Combat.actor(candidate)
            if root then
                local offset = root.Position - center
                if Vector3.new(offset.X, 0, offset.Z).Magnitude <= radius then
                    self.Combat:playerDamage(candidate, damage)
                end
            end
        end
        self.Combat:emit("impact", center, Color3.fromRGB(255, 100, 80), radius, nil, 0.5, enemy.Boss and 3 or 1, "force")
    end)
end

function Enemies:update()
    local now = os.clock()
    if self.Active then
        local activeEnemies = 0
        for _, enemy in ipairs(self.Combat.Enemies) do
            if enemy.Model.Parent and enemy.Humanoid.Health > 0 then activeEnemies = activeEnemies + 1 end
        end
        for roomNumber, room in ipairs(self.Rooms) do
            if not self.ActivatedRooms[roomNumber] then
                local close = false
                for player in pairs(self.Participants) do
                    local _, root = Combat.actor(player)
                    if root then
                        local offset = root.Position - room.Center
                        if Vector3.new(offset.X, 0, offset.Z).Magnitude <= 112 then close = true break end
                    end
                end
                if close and activeEnemies + #room.Enemies <= Config.EnemyLimit then
                    self:activateRoom(roomNumber)
                    activeEnemies = activeEnemies + #room.Enemies
                end
            end
        end
    end
    for index = #self.Combat.Enemies, 1, -1 do
        local enemy = self.Combat.Enemies[index]
        if not enemy.Model.Parent or enemy.Humanoid.Health <= 0 then
            table.remove(self.Combat.Enemies, index)
        else
            local movement = enemy.Behavior.Movement
            local player, targetRoot, distance = self:nearest(enemy.Root.Position, movement.AggroRange)
            local disabled = now < enemy.StunUntil or now < enemy.BreakUntil or enemy.Casting
            enemy.Humanoid.WalkSpeed = disabled and 0 or (enemy.Config.WalkSpeed * (now < enemy.SlowUntil and 0.45 or 1))
            if player and not disabled then
                if distance <= movement.AttackRange and now >= enemy.NextAttack then self:attack(enemy, player, targetRoot) end
                if now >= enemy.NextMove and distance > movement.StopRange then
                    enemy.NextMove = now + 0.3
                    enemy.Humanoid:MoveTo(targetRoot.Position)
                end
            end
        end
    end
end

return Enemies
