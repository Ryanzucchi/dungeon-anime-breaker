local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local effectRoot = script.Parent
local impactEffect = effectRoot:WaitForChild("scenery_impact")
local impactConfig = require(impactEffect:WaitForChild("config"))
local Impact = require(impactEffect:WaitForChild("logic"))
local Effects = {}
local folder = Instance.new("Folder")
folder.Name = "BreakmasmorrasLocalEffects"
folder.Parent = workspace

local function shape(size, frame, color, duration, transparency, cylinder, material)
    local objects = folder:GetChildren()
    if #objects >= impactConfig.MaxParts then objects[1]:Destroy() end
    local part = Instance.new("Part")
    part.Name, part.Size, part.CFrame, part.Color = "Effect", size, frame, color
    part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, false
    part.Material = material or Enum.Material.Neon
    part.Transparency = transparency or 0.3
    if cylinder then part.Shape = Enum.PartType.Cylinder end
    part.Parent = folder
    TweenService:Create(part, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Transparency = 1 }):Play()
    Debris:AddItem(part, duration + 0.08)
    return part
end

local function groundAt(position)
    local ignored = { folder }
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then table.insert(ignored, player.Character) end
    end
    local arena = workspace:FindFirstChild("BreakmasmorrasArena")
    if arena then
        for _, name in ipairs({ "Enemies", "Supports" }) do
            local group = arena:FindFirstChild(name)
            if group then table.insert(ignored, group) end
        end
    end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = ignored
    local result = workspace:Raycast(position + Vector3.new(0, 12, 0), Vector3.new(0, -48, 0), params)
    return result and (result.Position + Vector3.new(0, 0.06, 0)) or Vector3.new(position.X, 0.06, position.Z)
end

local function sceneryImpact(data)
    local qualityName = Impact.quality(Players.LocalPlayer:GetAttribute("DestructionQuality"))
    local quality, tier, level = Impact.settings(data.ImpactLevel, qualityName)
    local ground = groundAt(data.Position)
    local radius = math.clamp(data.Radius or 4, 2, 40) * tier.Scale
    local color = data.Color or Color3.fromRGB(210, 210, 220)
    local profile = data.ImpactProfile or "force"
    local life = quality.Lifetime

    if level >= 2 then
        local crater = shape(Vector3.new(0.12, radius * 1.35, radius * 1.35),
            CFrame.new(ground) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(58, 53, 51),
            life, 0.28, true, Enum.Material.Slate)
        crater.Name = "TemporaryCrater"
        local rim = shape(Vector3.new(0.09, radius * 1.72, radius * 1.72),
            CFrame.new(ground + Vector3.new(0, 0.025, 0)) * CFrame.Angles(0, 0, math.pi / 2), color,
            life * 0.75, 0.58, true, Enum.Material.SmoothPlastic)
        rim.Name = "ImpactRim"
    else
        shape(Vector3.new(0.08, radius * 1.2, radius * 1.2),
            CFrame.new(ground) * CFrame.Angles(0, 0, math.pi / 2), color, life * 0.65, 0.64, true)
    end

    local crackCount = quality.Cracks + (level - 1) * 2
    for index = 1, crackCount do
        local angle = (index / crackCount) * math.pi * 2 + math.random() * 0.18
        local length = radius * (0.38 + math.random() * 0.45)
        local distance = radius * (0.18 + math.random() * 0.12)
        local point = ground + Vector3.new(math.cos(angle) * distance, 0.035, math.sin(angle) * distance)
        local width = profile == "precision" and 0.12 or 0.22
        local crackColor = profile == "sand" and Color3.fromRGB(142, 119, 82) or Color3.fromRGB(37, 36, 40)
        shape(Vector3.new(width, 0.055, length), CFrame.new(point) * CFrame.Angles(0, -angle, 0),
            crackColor, life, 0.16, false, Enum.Material.Slate)
    end

    if profile == "rune" or profile == "arcane" then
        for index = 1, 8 do
            local angle = index / 8 * math.pi * 2
            local point = ground + Vector3.new(math.cos(angle) * radius * 0.64, 0.045, math.sin(angle) * radius * 0.64)
            shape(Vector3.new(0.16, 0.07, radius * 0.12), CFrame.new(point) * CFrame.Angles(0, -angle, 0),
                color, life * 0.8, 0.22, false, Enum.Material.Neon)
        end
    elseif profile == "precision" then
        for index = 1, 2 do
            local angle = (index - 1) * math.pi / 2 + math.pi / 4
            shape(Vector3.new(0.18, 0.06, radius * 1.55), CFrame.new(ground + Vector3.new(0, 0.055, 0)) * CFrame.Angles(0, -angle, 0),
                color, life * 0.75, 0.22, false, Enum.Material.Neon)
        end
    elseif profile == "sand" then
        for index = 1, quality.Debris do
            local angle = index / math.max(1, quality.Debris) * math.pi * 2
            local point = ground + Vector3.new(math.cos(angle) * radius * 0.72, 0.1, math.sin(angle) * radius * 0.72)
            shape(Vector3.new(0.45, 0.12, radius * 0.16), CFrame.new(point) * CFrame.Angles(0, -angle, 0),
                Color3.fromRGB(194, 164, 111), life * 0.8, 0.34, false, Enum.Material.Sand)
        end
    end

    local debrisCount = math.floor(quality.Debris * tier.DebrisScale)
    for index = 1, debrisCount do
        local angle = math.random() * math.pi * 2
        local distance = radius * (0.5 + math.random() * 0.55)
        local size = math.random(5, 12) / 10
        local point = ground + Vector3.new(math.cos(angle) * distance, 0.25, math.sin(angle) * distance)
        local rubble = shape(Vector3.new(size, size * 0.65, size), CFrame.new(point) * CFrame.Angles(math.random(), math.random(), math.random()),
            profile == "sand" and Color3.fromRGB(174, 148, 105) or Color3.fromRGB(105, 108, 116),
            life, 0.08, false, Enum.Material.Slate)
        TweenService:Create(rubble, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { CFrame = rubble.CFrame + Vector3.new(0, 0.7, 0), Size = rubble.Size * 0.25, Transparency = 1 }):Play()
    end
end

function Effects.show(data)
    if type(data) ~= "table" or typeof(data.Position) ~= "Vector3" then return end
    local position, color = data.Position, data.Color or Color3.new(1, 1, 1)
    local radius, duration = math.clamp(data.Radius or 4, 1, 40), math.clamp(data.Duration or 0.4, 0.1, 2)
    if data.Kind == "impact" then
        sceneryImpact(data)
    elseif data.Kind == "line" and data.Endpoint then
        local distance = (data.Endpoint - position).Magnitude
        if distance < 0.01 then return end
        shape(Vector3.new(math.max(0.4, radius * 0.5), 0.5, distance), CFrame.lookAt((position + data.Endpoint) / 2, data.Endpoint), color, duration)
    elseif data.Kind == "hit" or data.Kind == "dash" or data.Kind == "shield" then
        local orb = shape(Vector3.new(radius, radius, radius), CFrame.new(position), color, duration, 0.6)
        orb.Shape = Enum.PartType.Ball
    else
        local ground = Vector3.new(position.X, 0.15, position.Z)
        local disk = shape(Vector3.new(0.15, radius * 2, radius * 2), CFrame.new(ground) * CFrame.Angles(0, 0, math.pi / 2), color, duration, 0.65, true)
        if data.Kind == "telegraph" then
            disk.Material = Enum.Material.Neon
            for index = 1, 12 do
                local angle = index / 12 * math.pi * 2
                local point = ground + Vector3.new(math.cos(angle) * radius, 0.04, math.sin(angle) * radius)
                shape(Vector3.new(0.5, 0.2, radius * 0.5), CFrame.new(point) * CFrame.Angles(0, -angle, 0), color, duration, 0.1)
            end
        end
    end
end
return Effects
