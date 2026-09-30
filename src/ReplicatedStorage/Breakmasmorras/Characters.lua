local root = script.Parent:WaitForChild("characters")
local effects = require(script.Parent:WaitForChild("EffectCatalog"))
local characters = {}
for _, rarity in ipairs(root:GetChildren()) do
    if rarity:IsA("Folder") then
        for _, folder in ipairs(rarity:GetChildren()) do
            if folder:IsA("Folder") then
                local data = require(folder:WaitForChild("character"))
                local config = require(folder:WaitForChild("configs"))
                assert(data.Id == folder.Name, "Id de personagem inválido: " .. folder:GetFullName())
                assert(not characters[data.Id], "Id duplicado: " .. data.Id)
                assert(type(data.Color) == "table" and #data.Color == 3, "Cor inválida: " .. data.Id)
                data.Rarity = rarity.Name
                data.Color = Color3.fromRGB(data.Color[1], data.Color[2], data.Color[3])
                data.Passive, data.PassiveName, data.PassiveEffect = config.Passive, config.PassiveName, config.PassiveEffect
                data.Support, data.Skills = config.Support, config.Skills
                data.ImpactProfile = config.ImpactProfile or "force"
                assert(type(data.Skills) == "table" and type(data.Support) == "table", "Config incompleta: " .. data.Id)
                assert(effects[data.PassiveEffect] and effects[data.PassiveEffect].Logic,
                    "Efeito passivo ausente: " .. data.Id)
                assert(effects[data.Support.Effect] and type(effects[data.Support.Effect].Logic.Support) == "function",
                    "Efeito de Support ausente: " .. data.Id)
                for slot, ability in pairs(data.Skills) do
                    assert(type(ability.Effect) == "string" and effects[ability.Effect] and type(effects[ability.Effect].Logic.Skill) == "function",
                        "Efeito ausente para " .. data.Id .. "." .. slot)
                end
                characters[data.Id] = data
            end
        end
    end
end
return characters
