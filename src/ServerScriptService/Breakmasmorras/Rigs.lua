local Players = game:GetService("Players")
local Rigs = {}
local template

function Rigs.description()
    local description = Instance.new("HumanoidDescription")
    local gray = Color3.fromRGB(180, 185, 195)
    description.HeadColor = gray
    description.TorsoColor = gray
    description.LeftArmColor = gray
    description.RightArmColor = gray
    description.LeftLegColor = gray
    description.RightLegColor = gray
    return description
end

function Rigs.initialize()
    local description = Rigs.description()
    template = Players:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R15)
    description:Destroy()
    template.Name = "BasicR15"
    template.Archivable = true
    for _, child in ipairs(template:GetDescendants()) do
        if child:IsA("Script") or child:IsA("LocalScript") or child:IsA("Accessory") then child:Destroy() end
    end
end

function Rigs.spawn(parent, name, position, health, speed, tint)
    assert(template, "Rig template is not initialized")
    local model = template:Clone()
    model.Name = name
    model.Parent = parent
    model:PivotTo(CFrame.new(position))
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    humanoid.MaxHealth = health
    humanoid.Health = health
    humanoid.WalkSpeed = speed
    humanoid.DisplayName = name
    local root = model:FindFirstChild("HumanoidRootPart")
    model.PrimaryPart = root
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.CollisionGroup = "BreakmasmorrasActors"
            if tint then descendant.Color = tint end
        end
    end
    if root then root:SetNetworkOwner(nil) end
    return model, humanoid, root
end

return Rigs
