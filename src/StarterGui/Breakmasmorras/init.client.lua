local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Breakmasmorras")
local Characters, Config = require(Shared.Characters), require(Shared.Config)
local Rules = require(Shared.Rules)
local Effects = require(script.Effects)
local Animator = require(script.Animator)
local remotes = Shared:WaitForChild("Remotes")
local action, snapshot = remotes:WaitForChild("Action"), remotes:WaitForChild("Snapshot")
local order, slots = { "iruko", "renli", "gaoro", "kurino" }, { "Q", "E", "R", "F", "G" }
local state, holding, lastM1, lastAim = nil, false, 0, Vector3.zero
local lastInput = UserInputService:GetLastInputType()
UserInputService.LastInputTypeChanged:Connect(function(kind) lastInput = kind end)

local gui = Instance.new("ScreenGui")
gui.Name = "BreakmasmorrasHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")
local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 390, 0, 300)
panel.Position = UDim2.new(0, 12, 0, 12)
panel.BackgroundColor3 = Color3.fromRGB(24, 28, 36)
panel.BackgroundTransparency = 0.12
panel.Parent = gui
local scale = Instance.new("UIScale")
scale.Parent = panel
local function label(text, y, height)
    local value = Instance.new("TextLabel")
    value.Size = UDim2.new(1, -20, 0, height or 25)
    value.Position = UDim2.new(0, 10, 0, y)
    value.BackgroundTransparency = 1
    value.TextXAlignment = Enum.TextXAlignment.Left
    value.TextColor3 = Color3.fromRGB(230, 235, 245)
    value.Font = Enum.Font.Gotham
    value.TextSize = 14
    value.Text = text
    value.Parent = panel
    return value
end
local title = label("BREAKMASMORRAS · V1", 6)
title.Font = Enum.Font.GothamBold
title.Text = "BREAKMASMORRAS · V1.1"
local stats, progress = label("Carregando personagem...", 32), label("XP individual · sessão de teste", 58)
local supportLabel = label("Support: nenhum", 83)
local wave = label("Lobby · use o portal", 108)
local skillLabels = {}
for index, slot in ipairs(slots) do skillLabels[slot] = label(slot, 130 + (index - 1) * 22, 22) end
local passive = label("", 241, 36)
passive.TextWrapped, passive.TextSize = true, 12
label("M1 atacar · Space dash · 1 poção · T reagrupar", 277, 20).TextSize = 11

local function button(parent, text, position, size, callback)
    local value = Instance.new("TextButton")
    value.Size, value.Position = size, position
    value.BackgroundColor3 = Color3.fromRGB(46, 57, 75)
    value.TextColor3 = Color3.fromRGB(235, 240, 250)
    value.Font, value.TextSize, value.Text = Enum.Font.Gotham, 12, text
    value.Parent = parent
    value.Activated:Connect(callback)
    return value
end
local menu = Instance.new("Frame")
menu.Size = UDim2.new(0, 390, 0, 123)
menu.Position = UDim2.new(0, 12, 0, 322)
menu.BackgroundTransparency = 1
menu.Parent = gui
local menuScale = Instance.new("UIScale")
menuScale.Parent = menu
local collectionButtons = {}
for index, id in ipairs(order) do
    collectionButtons[id] = button(menu, Characters[id].Name, UDim2.new(0, (index - 1) * 98, 0, 0), UDim2.new(0, 92, 0, 30), function()
        action:FireServer("Select", id)
    end)
    button(menu, "+ Support", UDim2.new(0, (index - 1) * 98, 0, 34), UDim2.new(0, 92, 0, 27), function()
        action:FireServer("Support", id)
    end)
end
button(menu, "Entrar na dungeon", UDim2.new(0, 0, 0, 67), UDim2.new(1, 0, 0, 32), function() action:FireServer("Start") end)
local collection = Instance.new("Frame")
collection.Name = "Collection"
collection.Size = UDim2.new(0, 540, 0, 440)
collection.AnchorPoint = Vector2.new(0.5, 0.5)
collection.Position = UDim2.fromScale(0.5, 0.5)
collection.BackgroundColor3 = Color3.fromRGB(24, 28, 36)
collection.Visible = false
collection.Parent = gui
local collectionScale = Instance.new("UIScale")
collectionScale.Parent = collection
local heading = label("Coleção & Build", 8)
heading.Parent = collection
heading.Size = UDim2.new(1, -80, 0, 25)
button(collection, "Fechar", UDim2.new(1, -75, 0, 5), UDim2.new(0, 65, 0, 27), function() collection.Visible = false end)
local statusLabel = label("Carregando inventário...", 38, 48)
statusLabel.Parent = collection
statusLabel.TextWrapped = true
local odds = label("Banner de teste: Iruko 55%, Ren Li 20%, Kurino 20%, Gaoro 5%.\nShiny 1% após personagem. Rare garantido em até 10 rolls.", 86, 43)
odds.Parent = collection
odds.TextSize, odds.TextWrapped = 12, true
local list = Instance.new("ScrollingFrame")
list.Position, list.Size = UDim2.new(0, 10, 0, 138), UDim2.new(1, -20, 1, -148)
list.BackgroundTransparency, list.ScrollBarThickness = 1, 6
list.Parent = collection
local economyData, collectionSignature = nil, ""
local function rebuildCollection()
    if not state or not economyData then return end
    for _, child in ipairs(list:GetChildren()) do child:Destroy() end
    local y = 0
    local function rowText(text)
        local value = label(text, y, 25)
        value.Parent, value.Position, value.Size = list, UDim2.new(0, 0, 0, y), UDim2.new(1, -8, 0, 25)
        y = y + 29
    end
    rowText("PERSONAGENS · nível individual")
    for _, id in ipairs(order) do
        for _, unitId in ipairs({ id, id .. "_shiny" }) do
            local unit = state.Units[unitId]
            if unit then
                local key = unitId
                rowText(Characters[id].Name .. " · " .. string.upper(Characters[id].Rarity) .. (unit.Shiny and " · SHINY +20%" or "") .. " · Lv." .. unit.Level)
                button(list, state.Main == key and "Main equipado" or "Usar como Main", UDim2.new(0, 0, 0, y), UDim2.new(0.48, 0, 0, 26), function() action:FireServer("Select", key) end)
                button(list, state.Support == key and "Support equipado" or "Usar como Support", UDim2.new(0.5, 0, 0, y), UDim2.new(0.48, 0, 0, 26), function() action:FireServer("Support", key) end)
                y = y + 32
            end
        end
    end
    rowText("EQUIPAMENTOS · clique para equipar entre runs")
    local bonuses = { Weapon = "dano", Armor = "vida", Accessory = "velocidade", Artifact = "skills" }
    for _, item in ipairs(economyData.Inventory) do
        local itemId = item.Id
        local text = (economyData.Equipment[item.Slot] == itemId and "✓ " or "")
            .. item.Name .. " · " .. item.Rarity .. " · +" .. item.Power .. "% " .. bonuses[item.Slot]
        button(list, text, UDim2.new(0, 0, 0, y), UDim2.new(1, -8, 0, 29), function() action:FireServer("EquipItem", itemId) end)
        y = y + 34
    end
    if #economyData.Inventory == 0 then rowText("Derrote o boss para obter equipamentos.") end
    list.CanvasSize = UDim2.new(0, 0, 0, y)
end
button(menu, "Coleção & Build", UDim2.new(0, 0, 0, 103), UDim2.new(0.49, 0, 0, 29), function()
    collection.Visible = not collection.Visible
    holding = false
    rebuildCollection()
end)
button(menu, "Roll gratuito x1", UDim2.new(0.51, 0, 0, 103), UDim2.new(0.49, 0, 0, 29), function() action:FireServer("Roll") end)
remotes:WaitForChild("Economy").OnClientEvent:Connect(function(data)
    economyData = data
    rebuildCollection()
end)
local notice = Instance.new("TextLabel")
notice.Size, notice.Position = UDim2.new(0.8, 0, 0, 45), UDim2.new(0.1, 0, 1, -55)
notice.BackgroundTransparency = 0.25
notice.BackgroundColor3 = Color3.fromRGB(22, 26, 32)
notice.TextColor3, notice.TextSize, notice.TextWrapped = Color3.new(1, 1, 1), 16, true
notice.Font, notice.Text, notice.Parent = Enum.Font.Gotham, "Bem-vindo ao lobby. Use Z no portal ou o botão para entrar na dungeon.", gui
remotes:WaitForChild("Notice").OnClientEvent:Connect(function(message) notice.Text = message end)
remotes:WaitForChild("Effects").OnClientEvent:Connect(Effects.show)

local function aim()
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local camera = workspace.CurrentCamera
    if not root or not camera then return lastAim end
    local gamepad = string.find(lastInput.Name, "Gamepad") ~= nil
    if lastInput == Enum.UserInputType.Touch or gamepad then
        local arena = workspace:FindFirstChild("BreakmasmorrasArena")
        local enemies = arena and arena:FindFirstChild("Enemies")
        local nearest, best = 80, nil
        for _, model in ipairs(enemies and enemies:GetChildren() or {}) do
            local enemyRoot = model:FindFirstChild("HumanoidRootPart")
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            if enemyRoot and humanoid and humanoid.Health > 0 then
                local distance = (enemyRoot.Position - root.Position).Magnitude
                if distance < nearest then nearest, best = distance, enemyRoot.Position end
            end
        end
        return best or (root.Position + root.CFrame.LookVector * 20)
    end
    local mouse = UserInputService:GetMouseLocation()
    local ray = camera:ScreenPointToRay(mouse.X, mouse.Y)
    if math.abs(ray.Direction.Y) < 0.001 then return lastAim end
    local distance = -ray.Origin.Y / ray.Direction.Y
    if distance > 0 then lastAim = ray.Origin + ray.Direction * math.min(distance, 500) end
    return lastAim
end

local function cast(slot)
    if collection.Visible then return end
    if slot == "Dash" then
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local direction = humanoid and humanoid.MoveDirection or Vector3.zero
        if direction.Magnitude < 0.05 and root then direction = root.CFrame.LookVector end
        Animator.play("Dash")
        action:FireServer("Cast", slot, Vector3.new(direction.X, 0, direction.Z))
    else
        Animator.play(slot == "M1" and "Attack" or "Skill")
        action:FireServer("Cast", slot, aim())
    end
end
local keyMap = { Q = Enum.KeyCode.Q, E = Enum.KeyCode.E, R = Enum.KeyCode.R,
    F = Enum.KeyCode.F, G = Enum.KeyCode.G, Dash = Enum.KeyCode.Space }
local padMap = { Q = Enum.KeyCode.ButtonX, E = Enum.KeyCode.ButtonY, R = Enum.KeyCode.ButtonL1,
    F = Enum.KeyCode.ButtonR1, G = Enum.KeyCode.ButtonL2, Dash = Enum.KeyCode.ButtonA }
local touchPositions = {
    Q = UDim2.new(1, -230, 1, -170), E = UDim2.new(1, -155, 1, -170),
    R = UDim2.new(1, -230, 1, -95), F = UDim2.new(1, -155, 1, -95),
    G = UDim2.new(1, -80, 1, -170), Dash = UDim2.new(1, -80, 1, -95),
}
for slot, key in pairs(keyMap) do
    local boundSlot = slot
    ContextActionService:BindAction("Breakmasmorras" .. boundSlot, function(_, inputState)
        if UserInputService:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
        if inputState == Enum.UserInputState.Begin then cast(boundSlot) end
        return Enum.ContextActionResult.Sink
    end, true, key, padMap[boundSlot])
    ContextActionService:SetTitle("Breakmasmorras" .. boundSlot, boundSlot)
    ContextActionService:SetPosition("Breakmasmorras" .. boundSlot, touchPositions[boundSlot])
end
ContextActionService:BindAction("BreakmasmorrasBasic", function(_, inputState)
    if UserInputService:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
    if inputState == Enum.UserInputState.Begin then holding = true end
    if inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then holding = false end
    return Enum.ContextActionResult.Sink
end, true, Enum.KeyCode.ButtonR2)
ContextActionService:SetTitle("BreakmasmorrasBasic", "M1")
ContextActionService:SetPosition("BreakmasmorrasBasic", UDim2.new(1, -305, 1, -95))
ContextActionService:BindAction("BreakmasmorrasPotion", function(_, inputState)
    if UserInputService:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
    if inputState == Enum.UserInputState.Begin then action:FireServer("Potion") end
    return Enum.ContextActionResult.Sink
end, true, Enum.KeyCode.One, Enum.KeyCode.ButtonB)
ContextActionService:SetTitle("BreakmasmorrasPotion", "Poção")
ContextActionService:SetPosition("BreakmasmorrasPotion", UDim2.new(1, -305, 1, -170))
ContextActionService:BindAction("BreakmasmorrasSupport", function(_, inputState)
    if UserInputService:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
    if inputState == Enum.UserInputState.Begin then action:FireServer("SupportCommand") end
    return Enum.ContextActionResult.Sink
end, true, Enum.KeyCode.T, Enum.KeyCode.ButtonL3)
ContextActionService:SetTitle("BreakmasmorrasSupport", "Support")
ContextActionService:SetPosition("BreakmasmorrasSupport", UDim2.new(1, -380, 1, -95))
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then holding = true end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then holding = false end
end)
UserInputService.WindowFocusReleased:Connect(function() holding = false end)

snapshot.OnClientEvent:Connect(function(data)
    state = data
    local definition, unit = Characters[Rules.baseId(data.Main)], data.Units[data.Main]
    local signature = data.Main .. (data.Support or "")
    for _, id in ipairs(order) do
        collectionButtons[id].Text = data.Units[id] and Characters[id].Name or ("🔒 " .. Characters[id].Name)
        for _, key in ipairs({ id, id .. "_shiny" }) do
            if data.Units[key] then signature = signature .. key .. data.Units[key].Level end
        end
    end
    if signature ~= collectionSignature then collectionSignature = signature rebuildCollection() end
    if economyData then
        statusLabel.Text = string.format("Ouro %d · Rolls %d · Pity %d/%d\n%s", economyData.Gold, economyData.Spins,
            economyData.Pity, Config.RollPity, data.SaveStatus or "Carregando dados")
    end
    stats.Text = string.format("%s%s · Lv.%d   HP %d/%d", definition.Name, unit.Shiny and " ★" or "", unit.Level, math.floor(data.HP), math.floor(data.MaxHP))
    progress.Text = string.format("Energia %d/100 · Escudo %d · XP %d/%d", math.floor(data.Energy), math.floor(data.Shield), unit.XP, Config.xpForLevel(unit.Level))
    supportLabel.Text = data.Support and ("Support: " .. Characters[Rules.baseId(data.Support)].Name .. " · Lv." .. data.Units[data.Support].Level) or "Support: nenhum"
    if data.InDungeon then
        wave.Text = data.Active and ("Sala " .. data.Stage .. "/" .. data.PhaseCount .. " · " .. (data.PhaseName or "Caminho")) or "Retornando ao lobby"
    else
        wave.Text = "Lobby · entre pelo portal"
    end
    if data.Boss then
        wave.Text = string.format("%s · %d/%d HP · Postura %d/%d", data.Boss.Name or "Chefe", math.floor(data.Boss.HP),
            math.floor(data.Boss.MaxHP), math.floor(data.Boss.Posture), data.Boss.MaxPosture)
    end
    passive.Text = definition.PassiveName
    for _, slot in ipairs(slots) do
        local skill, cooldown = definition.Skills[slot], data.Cooldowns[slot] or 0
        skillLabels[slot].Text = string.format("%s · %s · %d energia%s", slot, skill.Name, skill.Cost,
            cooldown > 0 and string.format(" · %.1fs", cooldown) or "")
    end
end)

RunService:BindToRenderStep("BreakmasmorrasCamera", Enum.RenderPriority.Camera.Value + 1, function()
    local camera = workspace.CurrentCamera
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not camera then return end
    local factor = math.clamp(math.min(camera.ViewportSize.X / 820, camera.ViewportSize.Y / 620), 0.55, 1)
    scale.Scale, menuScale.Scale = factor, factor
    collectionScale.Scale = factor
    menu.Position = UDim2.new(0, 12, 0, 12 + 310 * factor)
    if root then
        camera.CameraType = Enum.CameraType.Scriptable
        camera.FieldOfView = 50
        camera.CFrame = CFrame.lookAt(root.Position + Config.CameraOffset, root.Position)
        if holding and not collection.Visible and os.clock() - lastM1 > 0.12 then lastM1 = os.clock() cast("M1") end
    end
end)
