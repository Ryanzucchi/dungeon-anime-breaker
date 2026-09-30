local Palette = require(script.Parent.Palette)
return {
    Grasslands = {
        Id = "Grasslands", GroundColor = Palette.Ground, GroundMaterial = Enum.Material.Grass,
        PathColor = Palette.Path, RockColor = Palette.Rock, CliffColor = Palette.Cliff,
        WaterColor = Palette.Water, VegetationColor = Palette.Vegetation,
        VegetationDensity = 0.75, RockDensity = 0.4, HeightVariance = 0.45,
        LandmarkProbability = 0.3, WaterProbability = 0.12,
    },
    RockyCanyon = {
        Id = "RockyCanyon", GroundColor = Color3.fromRGB(139, 100, 70), GroundMaterial = Enum.Material.Ground,
        PathColor = Color3.fromRGB(184, 137, 88), RockColor = Color3.fromRGB(165, 93, 51), CliffColor = Color3.fromRGB(105, 53, 40),
        WaterColor = Palette.Water, VegetationColor = Palette.Vegetation,
        VegetationDensity = 0.18, RockDensity = 0.92, HeightVariance = 0.95,
        LandmarkProbability = 0.42, WaterProbability = 0.08,
    },
    AncientRuins = {
        Id = "AncientRuins", GroundColor = Color3.fromRGB(157, 139, 103), GroundMaterial = Enum.Material.Sandstone,
        PathColor = Palette.Ruins, RockColor = Color3.fromRGB(147, 119, 82), CliffColor = Color3.fromRGB(101, 81, 60),
        WaterColor = Palette.Water, VegetationColor = Palette.Vegetation,
        VegetationDensity = 0.38, RockDensity = 0.52, HeightVariance = 0.52,
        LandmarkProbability = 0.86, WaterProbability = 0.15,
    },
    MountainPass = {
        Id = "MountainPass", GroundColor = Color3.fromRGB(105, 118, 112), GroundMaterial = Enum.Material.Rock,
        PathColor = Color3.fromRGB(165, 145, 113), RockColor = Color3.fromRGB(139, 99, 72), CliffColor = Color3.fromRGB(88, 61, 51),
        WaterColor = Palette.Water, VegetationColor = Color3.fromRGB(82, 119, 78),
        VegetationDensity = 0.3, RockDensity = 0.88, HeightVariance = 0.9,
        LandmarkProbability = 0.55, WaterProbability = 0.18,
    },
    LakeValley = {
        Id = "LakeValley", GroundColor = Color3.fromRGB(105, 145, 91), GroundMaterial = Enum.Material.Grass,
        PathColor = Color3.fromRGB(181, 147, 104), RockColor = Color3.fromRGB(137, 101, 73), CliffColor = Color3.fromRGB(99, 69, 53),
        WaterColor = Color3.fromRGB(50, 184, 207), VegetationColor = Color3.fromRGB(61, 142, 76),
        VegetationDensity = 0.68, RockDensity = 0.35, HeightVariance = 0.5,
        LandmarkProbability = 0.46, WaterProbability = 0.78, WaterForm = "Lake", LakeProbability = 0.45,
    },
}
