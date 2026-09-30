local root = script.Parent:WaitForChild("Themes")
local themes = {}
for _, folder in ipairs(root:GetChildren()) do
    if folder:IsA("Folder") then
        local module = folder:FindFirstChild("Theme")
        assert(module, "ThemePack sem Theme.lua: " .. folder.Name)
        local theme = require(module)
        assert(type(theme.Id) == "string" and theme.Id == folder.Name, "Id de ThemePack inválido: " .. folder.Name)
        for _, field in ipairs({ "Palette", "Biomes", "Props", "Structures", "StructureCategories", "Landmarks", "GroundRules", "CliffRules", "VegetationRules", "PathRules", "WaterRules" }) do
            assert(type(theme[field]) == "table", "ThemePack " .. theme.Id .. " sem contrato " .. field)
        end
        assert(next(theme.Biomes) ~= nil, "ThemePack sem biomas: " .. theme.Id)
        assert(type(theme.Props.Vegetation) == "table" and type(theme.Props.Rock) == "table", "ThemePack requer listas de vegetação e rochas: " .. theme.Id)
        assert(type(theme.VegetationRules.GroundCover) == "table", "ThemePack sem VegetationRules.GroundCover: " .. theme.Id)
        for _, color in ipairs({ "Rock", "Cliff", "Ruins", "Technology", "Accent" }) do
            assert(typeof(theme.Palette[color]) == "Color3", "ThemePack sem cor de paleta " .. color .. ": " .. theme.Id)
        end
        for biomeId, biome in pairs(theme.Biomes) do
            for _, field in ipairs({ "GroundColor", "GroundMaterial", "PathColor", "RockColor", "CliffColor", "WaterColor", "VegetationColor", "VegetationDensity", "RockDensity", "HeightVariance", "LandmarkProbability", "WaterProbability" }) do
                assert(biome[field] ~= nil, string.format("Biome %s do ThemePack %s sem %s", biomeId, theme.Id, field))
            end
        end
        local landmarkShapes = { Spire = true, Mesa = true, Temple = true, Arena = true, Pod = true, Crater = true, Waterfall = true, Arch = true }
        for _, landmark in ipairs(theme.Landmarks) do
            assert(type(landmark.Id) == "string" and landmarkShapes[landmark.Shape], "Landmark requer Id e Shape suportado: " .. theme.Id)
            assert(type(landmark.Weight) == "number" and type(landmark.Scale) == "table" and landmark.Category, "Configuração de landmark inválida: " .. theme.Id)
        end
        for structureId, structureItems in pairs(theme.Structures) do
            assert(type(structureId) == "string" and type(structureItems) == "table", "Estrutura inválida no ThemePack " .. theme.Id)
        end
        assert(not themes[theme.Id], "ThemePack duplicado: " .. theme.Id)
        themes[theme.Id] = theme
    end
end
local Registry = {}
function Registry.get(themeId)
    local theme = themes[themeId]
    assert(theme, "ThemePack não registrado: " .. tostring(themeId))
    return theme
end
function Registry.list()
    local ids = {}
    for id in pairs(themes) do table.insert(ids, id) end
    table.sort(ids)
    return ids
end
return Registry
