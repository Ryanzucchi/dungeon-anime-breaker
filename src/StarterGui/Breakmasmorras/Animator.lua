local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local Animator = {}
local activeClip, clipStarted = nil, 0
local cachedCharacter, cachedJoints = nil, {}
local function cacheCharacter(character)
    cachedCharacter, cachedJoints = character, {}
    for _, item in ipairs(character:GetDescendants()) do
        if item:IsA("Motor6D") then cachedJoints[item.Name] = item end
    end
end
player.CharacterAdded:Connect(cacheCharacter)
if player.Character then cacheCharacter(player.Character) end
function Animator.play(name)
    activeClip, clipStarted = name, os.clock()
end
RunService.PreSimulation:Connect(function()
    local character = player.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    if cachedCharacter ~= character then cacheCharacter(character) end
    local now = os.clock()
    local moving = humanoid.MoveDirection.Magnitude > 0.1
    local phase = now * (moving and 10 or 2.2)
    local bob = moving and math.sin(phase) * 0.08 or math.sin(phase) * 0.015
    local offsets = {
        Root = CFrame.new(0, bob, 0), RootJoint = CFrame.new(0, bob, 0), Waist = CFrame.new(0, bob, 0),
        RightShoulder = CFrame.Angles(math.sin(phase) * (moving and 0.22 or 0.035), 0, 0.06),
        LeftShoulder = CFrame.Angles(-math.sin(phase) * (moving and 0.22 or 0.035), 0, -0.06),
    }
    if activeClip then
        local t = now - clipStarted
        if t > 0.42 then
            activeClip = nil
        else
            local pulse = math.sin(math.clamp(t / 0.42, 0, 1) * math.pi)
            if activeClip == "Dash" then
                offsets.Root = CFrame.new(0, -0.22 * pulse, 0) * CFrame.Angles(math.rad(-24) * pulse, 0, 0)
                offsets.RootJoint, offsets.Waist = offsets.Root, offsets.Root
                offsets.RightShoulder = CFrame.Angles(math.rad(78) * pulse, 0, math.rad(18) * pulse)
                offsets.LeftShoulder = CFrame.Angles(math.rad(78) * pulse, 0, -math.rad(18) * pulse)
            elseif activeClip == "Attack" then
                offsets.Root = CFrame.Angles(0, math.rad(-18) * pulse, 0)
                offsets.RootJoint, offsets.Waist = offsets.Root, offsets.Root
                offsets.RightShoulder = CFrame.Angles(math.rad(-105) * pulse, 0, math.rad(35) * pulse)
                offsets.LeftShoulder = CFrame.Angles(math.rad(20) * pulse, 0, -math.rad(15) * pulse)
            else
                offsets.RightShoulder = CFrame.Angles(math.rad(-55) * pulse, 0, math.rad(25) * pulse)
                offsets.LeftShoulder = CFrame.Angles(math.rad(25) * pulse, 0, -math.rad(20) * pulse)
            end
        end
    end
    for name, offset in pairs(offsets) do
        local joint = cachedJoints[name]
        if joint then joint.Transform = joint.Transform * offset end
    end
end)
return Animator
