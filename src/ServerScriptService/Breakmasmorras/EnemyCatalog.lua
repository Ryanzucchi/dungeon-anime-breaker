local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Breakmasmorras")
local dataRoot = Shared:WaitForChild("enemies")
local logicRoot = script.Parent:WaitForChild("EnemyLogic")
local catalog = {}
for _, family in ipairs(dataRoot:GetChildren()) do
    if family:IsA("Folder") then
        for _, folder in ipairs(family:GetChildren()) do
            if folder:IsA("Folder") then
                local identityModule = folder:FindFirstChild("enemy")
                local configModule = folder:FindFirstChild("configs")
                assert(identityModule and configModule, "Inimigo incompleto: " .. folder:GetFullName())
                local identity, config = require(identityModule), require(configModule)
                assert(identity.Id == folder.Name, "Id de inimigo inválido: " .. folder:GetFullName())
                assert(identity.Family == family.Name, "Família inválida: " .. identity.Id)
                assert(type(identity.Type) == "string" and type(identity.Name) == "string", "Identidade inválida: " .. identity.Id)
                assert(type(identity.Color) == "table" and #identity.Color == 3, "Cor inválida: " .. identity.Id)
                identity.Color = Color3.fromRGB(identity.Color[1], identity.Color[2], identity.Color[3])
                assert(not catalog[identity.Type], "Tipo de inimigo duplicado: " .. identity.Type)
                assert(type(config.MaxHealth) == "number" and config.MaxHealth > 0, "Vida inválida: " .. identity.Id)
                assert(type(config.WalkSpeed) == "number" and config.WalkSpeed > 0, "Velocidade inválida: " .. identity.Id)
                assert(type(config.MaxPosture) == "number" and config.MaxPosture > 0, "Postura inválida: " .. identity.Id)
                assert(type(config.RewardXP) == "number" and config.RewardXP >= 0, "Recompensa inválida: " .. identity.Id)
                local logicModule = logicRoot:FindFirstChild(config.LogicId)
                assert(logicModule, "Lógica ausente: " .. identity.Id .. " / " .. tostring(config.LogicId))
                local behavior = require(logicModule)
                assert(type(behavior.Attack) == "table" and type(behavior.Movement) == "table", "Comportamento incompleto: " .. identity.Id)
                assert(type(behavior.Attack.Cooldown) == "number" and type(behavior.Attack.Windup) == "number"
                    and type(behavior.Attack.Damage) == "number" and type(behavior.Attack.Radius) == "number",
                    "Perfil de ataque incompleto: " .. identity.Id)
                catalog[identity.Type] = { Identity = identity, Config = config, Behavior = behavior }
            end
        end
    end
end
for _, kind in ipairs({ "melee", "ranged", "elite", "mini_boss", "boss" }) do
    assert(catalog[kind], "Tipo de inimigo obrigatório ausente: " .. kind)
end
return catalog
