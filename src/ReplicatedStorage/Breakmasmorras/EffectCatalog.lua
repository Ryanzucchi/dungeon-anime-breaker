local root = script.Parent:WaitForChild("effects")
local catalog = {}
for _, folder in ipairs(root:GetChildren()) do
    if folder:IsA("Folder") then
        local configModule = folder:FindFirstChild("config")
        local logicModule = folder:FindFirstChild("logic")
        assert(configModule and logicModule, "Efeito incompleto: " .. folder.Name)
        local config, logic = require(configModule), require(logicModule)
        assert(type(config.Id) == "string" and config.Id == folder.Name, "Id de efeito inválido: " .. folder.Name)
        assert(type(logic) == "table", "Lógica inválida: " .. folder.Name)
        assert(not catalog[config.Id], "Id de efeito duplicado: " .. config.Id)
        catalog[config.Id] = {Config=config, Logic=logic}
    end
end
return catalog
